/**
 * femora-app/backend/server.js
 *
 * OWASP-hardened Express API for Femora
 * Security features:
 *   1. Rate limiting  — IP-based on all public routes, tighter on auth
 *   2. Input validation & sanitization — schema-based via express-validator
 *   3. Secure API key handling — all secrets via .env, none hard-coded
 *   4. Helmet security headers
 *   5. CORS locked to known origins
 *   6. Payload size cap (prevents large-body DoS)
 *   7. Generic error messages on auth (prevents user enumeration)
 */

'use strict';

require('dotenv').config();

const express      = require('express');
const cors         = require('cors');
const helmet       = require('helmet');
const morgan       = require('morgan');
const rateLimit    = require('express-rate-limit');
const { body, query, validationResult } = require('express-validator');
const { createClient }  = require('@supabase/supabase-js');

// ─── 1. Fail fast if required environment variables are missing ───────────────
//     OWASP A05 – Security Misconfiguration: never start with missing secrets
const REQUIRED_ENV = ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'PORT'];
const missing = REQUIRED_ENV.filter(k => !process.env[k]);
if (missing.length) {
  console.error(`[FATAL] Missing required env vars: ${missing.join(', ')}`);
  console.error('[FATAL] Copy .env.example → .env and fill in every value.');
  process.exit(1);
}

// ─── 2. Supabase admin client — SERVICE KEY, server-side only ────────────────
//     OWASP A02 – Cryptographic Failures: service key never sent to client
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY   // Full DB access — server only
);

// ─── 3. App init ─────────────────────────────────────────────────────────────
const app  = express();
const PORT = parseInt(process.env.PORT, 10) || 3000;

// ─── 4. Security headers via Helmet ──────────────────────────────────────────
//     OWASP A05 – Secure HTTP headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      connectSrc: ["'self'", process.env.SUPABASE_URL],
    },
  },
  hsts: { maxAge: 31536000, includeSubDomains: true },
}));

// ─── 5. CORS — only allow known origins ──────────────────────────────────────
//     OWASP A05 – never use wildcard * in production
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000')
  .split(',').map(o => o.trim());

app.use(cors({
  origin: (origin, cb) => {
    // Mobile apps (Flutter) send no Origin header — allow them
    if (!origin || ALLOWED_ORIGINS.includes(origin)) return cb(null, true);
    cb(new Error(`CORS blocked: ${origin}`));
  },
  methods:        ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials:    true,
}));

// ─── 6. Body parsing with size limit ────────────────────────────────────────
//     OWASP A05 – prevent large-payload DoS
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: false, limit: '10kb' }));

// ─── 7. Request logging ───────────────────────────────────────────────────────
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// ═════════════════════════════════════════════════════════════════════════════
// RATE LIMITERS  (OWASP A04 – Insecure Design: prevent brute force / DoS)
// ═════════════════════════════════════════════════════════════════════════════

/**
 * Build a rate limiter with a clear 429 JSON response.
 * @param {number} windowMs  Time window in ms
 * @param {number} max       Max requests per window per IP
 * @param {string} msg       Message shown to the caller
 */
const makeLimiter = (windowMs, max, msg) => rateLimit({
  windowMs,
  max,
  standardHeaders: true,   // RateLimit-* headers (RFC 6585)
  legacyHeaders:   false,
  handler: (_req, res) => res.status(429).json({
    status:  429,
    error:   'Too Many Requests',
    message: msg,
    retryAfterSeconds: Math.ceil(windowMs / 1000),
  }),
  skip: () => process.env.NODE_ENV === 'test',
});

// Auth endpoints — very tight (prevent credential stuffing)
const authLimiter = makeLimiter(
  15 * 60 * 1000,   // 15-minute window
  10,               // 10 attempts per IP
  'Too many login attempts from this IP. Please wait 15 minutes.'
);

// General read endpoints
const apiLimiter = makeLimiter(
  60 * 1000,   // 1 minute
  60,          // 60 requests/min
  'Too many requests. Please slow down.'
);

// Write endpoints — tighter than reads
const writeLimiter = makeLimiter(
  60 * 1000,
  20,
  'Write rate limit exceeded. Please wait before submitting again.'
);

// ═════════════════════════════════════════════════════════════════════════════
// INPUT VALIDATION HELPERS  (OWASP A03 – Injection)
// ═════════════════════════════════════════════════════════════════════════════

/**
 * Strip HTML tags from a string value.
 * Belt-and-braces sanitisation after express-validator normalises input.
 */
const stripHtml = v => (typeof v === 'string' ? v.replace(/<[^>]*>/g, '').trim() : v);

/**
 * Middleware: if express-validator found errors → 422 with structured detail.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      status:  422,
      error:   'Validation Failed',
      details: errors.array().map(e => ({ field: e.path, message: e.msg })),
    });
  }
  next();
};

/**
 * Rejects any request body keys not in the provided whitelist.
 * OWASP A03 – Mass Assignment / injection via unexpected fields.
 */
const allowOnly = (...fields) => body().custom((_, { req }) => {
  const unexpected = Object.keys(req.body || {}).filter(k => !fields.includes(k));
  if (unexpected.length) throw new Error(`Unexpected fields: ${unexpected.join(', ')}`);
  return true;
});

// ─── Reusable field rules ────────────────────────────────────────────────────
const rules = {
  email: body('email')
    .trim().isEmail().withMessage('Must be a valid email address')
    .normalizeEmail()
    .isLength({ max: 255 }).withMessage('Email too long'),

  password: body('password')
    .isString().isLength({ min: 8, max: 128 })
    .withMessage('Password must be 8–128 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain uppercase, lowercase and a number'),

  passwordLogin: body('password')
    .isString().notEmpty().withMessage('Password is required')
    .isLength({ max: 128 }).withMessage('Password too long'),

  fullName: body('full_name')
    .trim().isString().isLength({ min: 2, max: 100 })
    .withMessage('Name must be 2–100 characters')
    .matches(/^[a-zA-Z\s'\-]+$/).withMessage('Name contains invalid characters')
    .customSanitizer(stripHtml),

  dateISO: field => body(field)
    .optional().isISO8601().withMessage(`${field} must be a valid date (YYYY-MM-DD)`).toDate(),

  intRange: (field, min, max) => body(field)
    .optional().isInt({ min, max }).withMessage(`${field} must be ${min}–${max}`)
    .toInt(),

  shortText: (field, maxLen = 500) => body(field)
    .optional().isString().isLength({ max: maxLen })
    .withMessage(`${field} must not exceed ${maxLen} characters`)
    .customSanitizer(stripHtml),
};

// ═════════════════════════════════════════════════════════════════════════════
// AUTH MIDDLEWARE  (OWASP A01 – Broken Access Control)
// ═════════════════════════════════════════════════════════════════════════════

/**
 * Verify the Supabase JWT from the Authorization: Bearer header.
 * Attaches req.user on success; returns 401 on failure.
 */
const requireAuth = async (req, res, next) => {
  try {
    const header = req.headers.authorization || '';
    if (!header.startsWith('Bearer ')) {
      return res.status(401).json({ status: 401, error: 'Unauthorized', message: 'Missing Bearer token.' });
    }
    const token = header.slice(7);
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return res.status(401).json({ status: 401, error: 'Unauthorized', message: 'Invalid or expired token.' });
    }
    req.user = user;
    next();
  } catch (err) { next(err); }
};

// ═════════════════════════════════════════════════════════════════════════════
// ROUTES
// ═════════════════════════════════════════════════════════════════════════════

// ── Health ───────────────────────────────────────────────────────────────────
app.get('/', (_req, res) => res.json({ name: 'Femora API', status: 'running', version: '1.0.0' }));
app.get('/health', (_req, res) => res.json({ status: 'healthy', uptime: process.uptime(), timestamp: new Date() }));

// ── Auth — POST /api/auth/signup ─────────────────────────────────────────────
app.post('/api/auth/signup',
  authLimiter,                        // IP rate limit: 10/15 min
  [
    rules.email,
    rules.password,
    rules.fullName,
    allowOnly('email', 'password', 'full_name'),   // reject extra fields
  ],
  validate,
  async (req, res, next) => {
    try {
      const { email, password, full_name } = req.body;

      const { data, error } = await supabase.auth.admin.createUser({
        email,
        password,
        user_metadata: { full_name: stripHtml(full_name) },
        email_confirm: false,
      });

      if (error) {
        // OWASP A07 – do NOT expose whether email already exists
        console.error('[Auth/signup]', error.message);
        return res.status(400).json({ status: 400, error: 'Signup Failed', message: 'Could not create account. Check your details.' });
      }

      res.status(201).json({
        status: 201, message: 'Account created.',
        user: { id: data.user.id, email: data.user.email },
      });
    } catch (err) { next(err); }
  }
);

// ── Auth — POST /api/auth/login ───────────────────────────────────────────────
app.post('/api/auth/login',
  authLimiter,
  [rules.email, rules.passwordLogin, allowOnly('email', 'password')],
  validate,
  async (req, res, next) => {
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email:    req.body.email,
        password: req.body.password,
      });

      if (error) {
        // Generic message — never say "email not found" or "wrong password"
        return res.status(401).json({ status: 401, error: 'Login Failed', message: 'Invalid email or password.' });
      }

      res.status(200).json({
        status: 200, message: 'Login successful.',
        session: {
          access_token:  data.session.access_token,
          refresh_token: data.session.refresh_token,
          expires_at:    data.session.expires_at,
        },
        user: { id: data.user.id, email: data.user.email },
      });
    } catch (err) { next(err); }
  }
);

// ── Auth — POST /api/auth/logout ─────────────────────────────────────────────
app.post('/api/auth/logout', requireAuth, apiLimiter, async (req, res, next) => {
  try {
    // Use admin API to sign out the authenticated user and revoke all their sessions
    const { error } = await supabase.auth.admin.signOut(req.user.id);
    if (error) throw error;
    res.json({ status: 200, message: 'Logged out.' });
  } catch (err) { next(err); }
});

// ── Profile — GET /api/profile ────────────────────────────────────────────────
app.get('/api/profile', requireAuth, apiLimiter, async (req, res, next) => {
  try {
    const { data, error } = await supabase.from('profiles')
      .select('full_name, date_of_birth, profile_avatar, onboarding_completed')
      .eq('id', req.user.id).single();

    if (error) return res.status(404).json({ status: 404, error: 'Not Found', message: 'Profile not found.' });
    res.json({ status: 200, data });
  } catch (err) { next(err); }
});

// ── Profile — PATCH /api/profile ─────────────────────────────────────────────
app.patch('/api/profile', requireAuth, writeLimiter,
  [
    rules.fullName.optional(),
    rules.dateISO('date_of_birth'),
    body('onboarding_completed').optional().isBoolean().toBoolean(),
    allowOnly('full_name', 'date_of_birth', 'onboarding_completed'),
  ],
  validate,
  async (req, res, next) => {
    try {
      const updates = {};
      if (req.body.full_name !== undefined)            updates.full_name            = stripHtml(req.body.full_name);
      if (req.body.date_of_birth !== undefined)        updates.date_of_birth        = req.body.date_of_birth.toISOString().split('T')[0];
      if (req.body.onboarding_completed !== undefined) updates.onboarding_completed = req.body.onboarding_completed;

      const { data, error } = await supabase.from('profiles')
        .update(updates).eq('id', req.user.id).select().single();

      if (error) { console.error('[Profile/update]', error.message); return res.status(500).json({ status: 500, error: 'Server Error', message: 'Update failed.' }); }
      res.json({ status: 200, message: 'Profile updated.', data });
    } catch (err) { next(err); }
  }
);

// ── Period — POST /api/period/log ────────────────────────────────────────────
app.post('/api/period/log', requireAuth, writeLimiter,
  [
    body('log_date').isISO8601().withMessage('log_date must be YYYY-MM-DD').toDate(),
    body('flow_level').isIn(['spotting', 'light', 'medium', 'heavy']).withMessage('Invalid flow_level'),
    rules.intRange('pain_level', 0, 10),
    body('symptoms').optional().isArray({ max: 20 }).withMessage('symptoms must be an array (max 20)'),
    body('symptoms.*').optional().isString().isLength({ max: 50 }),
    rules.shortText('notes', 500),
    body('mood').optional().isString().isLength({ max: 50 }).customSanitizer(stripHtml),
    allowOnly('log_date', 'flow_level', 'pain_level', 'symptoms', 'notes', 'mood'),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { log_date, flow_level, pain_level, symptoms, notes, mood } = req.body;
      const { data, error } = await supabase.from('period_daily_logs').upsert({
        user_id: req.user.id,
        log_date: log_date.toISOString().split('T')[0],
        flow_level, pain_level: pain_level ?? null,
        symptoms: symptoms ?? [],
        notes: notes ? stripHtml(notes) : null,
        mood: mood ? stripHtml(mood) : null,
      }).select().single();

      if (error) { console.error('[Period/log]', error.message); return res.status(500).json({ status: 500, error: 'Server Error', message: 'Failed to save.' }); }
      res.status(201).json({ status: 201, message: 'Period log saved.', data });
    } catch (err) { next(err); }
  }
);

// ── Period — GET /api/period/history ─────────────────────────────────────────
app.get('/api/period/history', requireAuth, apiLimiter,
  [query('limit').optional().isInt({ min: 1, max: 90 }).toInt()],
  validate,
  async (req, res, next) => {
    try {
      const limit = req.query.limit || 30;
      const { data, error } = await supabase.from('period_daily_logs')
        .select('id, log_date, flow_level, pain_level, symptoms, mood, created_at')
        .eq('user_id', req.user.id)
        .order('log_date', { ascending: false })
        .limit(limit);

      if (error) return res.status(500).json({ status: 500, error: 'Server Error', message: 'Fetch failed.' });
      res.json({ status: 200, data, count: data.length });
    } catch (err) { next(err); }
  }
);

// ── Mood — POST /api/mood/log ─────────────────────────────────────────────────
app.post('/api/mood/log', requireAuth, writeLimiter,
  [
    body('mood_score').isInt({ min: 0, max: 100 }).withMessage('mood_score must be 0–100').toInt(),
    body('mood_emoji').optional().isString().isLength({ max: 10 }),
    body('mood_tags').optional().isArray({ max: 10 }),
    body('mood_tags.*').optional().isString().isLength({ max: 30 }),
    rules.shortText('notes', 500),
    rules.intRange('energy_level', 1, 10),
    rules.intRange('stress_level', 1, 10),
    allowOnly('mood_score', 'mood_emoji', 'mood_tags', 'notes', 'energy_level', 'stress_level'),
  ],
  validate,
  async (req, res, next) => {
    try {
      const { mood_score, mood_emoji, mood_tags, notes, energy_level, stress_level } = req.body;
      const { data, error } = await supabase.from('mood_logs').insert({
        user_id: req.user.id,
        log_date: new Date().toISOString().split('T')[0],
        mood_score, mood_emoji: mood_emoji || null,
        mood_tags: mood_tags || [],
        notes: notes ? stripHtml(notes) : null,
        energy_level: energy_level || null,
        stress_level: stress_level || null,
      }).select().single();

      if (error) { console.error('[Mood/log]', error.message); return res.status(500).json({ status: 500, error: 'Server Error', message: 'Failed to save.' }); }
      res.status(201).json({ status: 201, message: 'Mood log saved.', data });
    } catch (err) { next(err); }
  }
);

// ─── 404 ──────────────────────────────────────────────────────────────────────
app.use((req, res) => res.status(404).json({
  status: 404, error: 'Not Found',
  message: `${req.method} ${req.originalUrl} does not exist.`,
}));

// ─── Global error handler ─────────────────────────────────────────────────────
//     OWASP A09 – never leak stack traces to clients in production
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  console.error('[Unhandled]', err.message);
  if (process.env.NODE_ENV !== 'production') {
    return res.status(500).json({ status: 500, error: err.name, message: err.message, stack: err.stack });
  }
  res.status(500).json({ status: 500, error: 'Internal Server Error', message: 'Something went wrong.' });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n🌸  Femora API`);
  console.log(`    http://localhost:${PORT}`);
  console.log(`    env        : ${process.env.NODE_ENV || 'development'}`);
  console.log(`    rate limits: ✅   headers: ✅   validation: ✅\n`);
});

module.exports = app;