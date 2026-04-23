# Supabase OTP Authentication - Debugging Guide

## Your Error: "Authentication Failed"

The improved error handling will now show you the **actual Supabase error message**. When you run the app again, check the console logs for `⚠️ Supabase OTP Error:` which will tell you the exact problem.

---

## Common Causes & Solutions

### 1. ❌ Email Provider Not Enabled in Supabase

**Check this first:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project: **eqwhrlpmkgokygucogvw**
3. Go to **Authentication** → **Providers**
4. Look for **Email** provider
5. Make sure it's **ENABLED** (toggle should be ON)

**If disabled:**
- Click the **Email** provider
- Toggle it ON
- Save changes

---

### 2. ❌ Email Configuration Issues

**Check these settings in your Email provider:**

Go to: **Authentication** → **Providers** → **Email** → **Settings**

Make sure:
- ✅ **Email Confirmations** is set appropriately:
  - For testing: **Disable** email confirmation (sign in immediately)
  - For production: **Enable** confirmation (user confirms via email)
  
- ✅ **Secure Email Change** is handled
- ✅ **Email Template** if you want custom branding

**If you're using a Free Supabase project:**
- It might limit email sends (usually 1 per minute per user in dev)
- Wait before retrying the same email

---

### 3. ❌ Wrong Supabase Credentials

**Verify your .env file is correct:**

File: `mobile/.env`

```dotenv
SUPABASE_URL=https://eqwhrlpmkgokygucogvw.supabase.co
SUPABASE_ANON_KEY=sb_publishable_SIql-lTYGw1anppAGyiWZA_O_bn1a8J
```

**Get correct credentials:**
1. Supabase Dashboard → Your Project
2. Click **Settings** (gear icon)
3. Go to **API** tab
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **Anon public key** → `SUPABASE_ANON_KEY`

⚠️ **Important:** Make sure you're copying the **Anon public key**, NOT the service key!

---

### 4. ❌ Rate Limiting

**Error message will contain:** `rate` or `rate_limit`

**Solution:**
- Wait a few minutes before trying again
- Don't retry the same email more than once per minute
- For testing, use different email addresses

---

### 5. ❌ Network/Connectivity Issues

**Error message will contain:** `connection` or `network`

**Solution:**
- Check your internet connection
- On emulator: Make sure network access is enabled
- On physical device: Try on WiFi

---

## Debugging Steps

### 1️⃣ Check Console Output

**Run the app and look for:**
```
⚠️ Supabase OTP Error: [ACTUAL ERROR MESSAGE]
```

This will tell you the **exact** problem from Supabase.

### 2️⃣ Verify Email Provider is Enabled

1. Supabase Dashboard
2. Authentication → Providers
3. Email provider should show a **green checkmark** ✅

### 3️⃣ Test from Supabase Console

You can test OTP directly from Supabase:

1. Supabase Dashboard → Authentication → Users
2. Click "Create a new user"
3. Enter test email
4. Check if an OTP email is sent (check spam folder)

If no email is sent here either, the problem is your Supabase setup, not our code.

### 4️⃣ Check Email Delivery

**If Supabase tries to send email:**
- Check spam/junk folder
- Check that email address is valid
- Check Supabase logs in Dashboard → Logs tab

---

## Email Configuration Recommendations

### For Development/Testing:
```
✅ Email Provider: Enabled
✅ Email Confirmation: DISABLED (user signs in immediately)
✅ Email Template: Default
✅ Auto confirm users: Enabled (faster testing)
```

### For Production:
```
✅ Email Provider: Enabled
✅ Email Confirmation: ENABLED (user must confirm email)
✅ Email Template: Custom with your branding
✅ Auto confirm users: Disabled
```

---

## Error Message Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `email_not_confirmed` | Email confirmation required | User needs to click email link first |
| `invalid_grant` | Credentials/token invalid | Check .env credentials |
| `mfa_required` | User has 2FA enabled | Handle MFA flow (advanced) |
| `rate_limit_exceeded` | Too many requests | Wait and retry |
| `connection_refused` | Network issue | Check internet connection |
| `user_already_exists` | Email already registered | User should sign in instead |
| `supabase_error` | API error | Check Supabase logs |

---

## Next Steps

1. **Run the app again** and check console for the actual error
2. **Screenshot the error** and the console logs
3. **Verify Email Provider is ENABLED** in Supabase
4. **Try a different email address** to rule out rate limiting
5. **Check Supabase Logs** (Dashboard → Logs) for the actual API error

---

## Code Changes Made

✅ Added detailed error logging:
```dart
print('⚠️ Supabase OTP Error: ${e.message}');
```

✅ Improved error message mapping with more specific conditions

✅ Extended SnackBar duration to 5 seconds so you have time to read error

**Now when you click "Send OTP", you'll see the actual Supabase error message in your console!**
