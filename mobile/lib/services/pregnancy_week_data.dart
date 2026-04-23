// Pregnancy Week Data Service
//
// Contains medically accurate information for all 40 weeks:
// - Baby size (fruit comparison, length, weight)
// - Baby development milestones
// - Mother symptoms and tips
//
// Sources: Mayo Clinic, NHS, American College of Obstetricians
// and Gynecologists (ACOG) average fetal measurements.

class PregnancyWeekInfo {
  final int week;
  final String fruitEmoji;
  final String fruitName;
  final String sizeCaption;   // "Your baby is as big as a lime"
  final double lengthCm;
  final double weightG;
  final List<String> babyMilestones;  // 3 items max
  final List<String> momTips;         // 2-3 items max
  final String babyImageAsset;        // emoji used as animated display
  final String weekHighlight;         // one-sentence hero text

  const PregnancyWeekInfo({
    required this.week,
    required this.fruitEmoji,
    required this.fruitName,
    required this.sizeCaption,
    required this.lengthCm,
    required this.weightG,
    required this.babyMilestones,
    required this.momTips,
    required this.babyImageAsset,
    required this.weekHighlight,
  });
}

class PregnancyWeekDataService {
  static PregnancyWeekDataService? _instance;
  static PregnancyWeekDataService get instance =>
      _instance ??= PregnancyWeekDataService._();
  PregnancyWeekDataService._();

  /// Returns week info for any week 1–42.
  /// Clamps to available data range.
  PregnancyWeekInfo getWeekInfo(int week) {
    final clamped = week.clamp(1, 40);
    return _data[clamped - 1];
  }

  static const List<PregnancyWeekInfo> _data = [
    // ── Week 1 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 1,
      fruitEmoji: '🌱',
      fruitName: 'Poppy Seed',
      sizeCaption: 'Smaller than a poppy seed',
      lengthCm: 0.1,
      weightG: 0.0,
      babyMilestones: [
        'Fertilisation occurs this week',
        'The single cell begins dividing rapidly',
        'The blastocyst travels toward the uterus',
      ],
      momTips: [
        'Start taking folic acid 400mcg daily if not already',
        'Avoid alcohol, smoking, and raw foods',
      ],
      babyImageAsset: '🌱',
      weekHighlight: 'Your incredible journey begins.',
    ),
    // ── Week 2 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 2,
      fruitEmoji: '🌱',
      fruitName: 'Poppy Seed',
      sizeCaption: 'About the size of a poppy seed',
      lengthCm: 0.2,
      weightG: 0.0,
      babyMilestones: [
        'Implantation into the uterine lining',
        'The embryo begins to form two distinct layers',
        'The placenta starts developing',
      ],
      momTips: [
        'You may experience light implantation spotting — this is normal',
        'Stay hydrated and rest well',
      ],
      babyImageAsset: '🌱',
      weekHighlight: 'Implantation — your baby is settling in.',
    ),
    // ── Week 3 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 3,
      fruitEmoji: '🫐',
      fruitName: 'Blueberry seed',
      sizeCaption: 'Tinier than a grain of rice',
      lengthCm: 0.3,
      weightG: 0.0,
      babyMilestones: [
        'Three distinct cell layers are forming',
        'The neural tube (brain & spine) begins to develop',
        'A primitive heart begins to form',
      ],
      momTips: [
        'Home pregnancy test will show positive around now',
        'Book your first antenatal appointment',
      ],
      babyImageAsset: '🫐',
      weekHighlight: 'The very first heartbeat cells are forming.',
    ),
    // ── Week 4 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 4,
      fruitEmoji: '🌺',
      fruitName: 'Poppy',
      sizeCaption: 'About the size of a poppy flower',
      lengthCm: 0.4,
      weightG: 0.0,
      babyMilestones: [
        'The embryo is now the size of a poppy seed',
        'The yolk sac is providing nutrients',
        'Basic body structures are forming',
      ],
      momTips: [
        'Morning sickness may begin',
        'Avoid ibuprofen — use paracetamol only if needed',
      ],
      babyImageAsset: '🌺',
      weekHighlight: 'Your period is late — confirm with a test!',
    ),
    // ── Week 5 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 5,
      fruitEmoji: '🍫',
      fruitName: 'Sesame Seed',
      sizeCaption: 'About the size of a sesame seed',
      lengthCm: 0.5,
      weightG: 0.0,
      babyMilestones: [
        'The heart begins beating at ~100 bpm',
        'Eyes and ears are starting to form',
        'Tiny arm and leg buds are visible',
      ],
      momTips: [
        'Fatigue and breast tenderness are common — rest when you can',
        'Eat small frequent meals to manage nausea',
      ],
      babyImageAsset: '🫘',
      weekHighlight: 'First heartbeat! 💓',
    ),
    // ── Week 6 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 6,
      fruitEmoji: '🫐',
      fruitName: 'Sweet Pea',
      sizeCaption: 'About the size of a sweet pea',
      lengthCm: 0.6,
      weightG: 0.0,
      babyMilestones: [
        'Facial features are forming — nose, jaw, cheeks',
        'The brain is growing rapidly',
        'Fingers and toes are beginning to form',
      ],
      momTips: [
        'Stay away from cat litter (toxoplasmosis risk)',
        'Ginger tea can help with morning sickness',
      ],
      babyImageAsset: '🫐',
      weekHighlight: 'Your baby\'s face is beginning to take shape.',
    ),
    // ── Week 7 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 7,
      fruitEmoji: '🫐',
      fruitName: 'Blueberry',
      sizeCaption: 'About the size of a blueberry',
      lengthCm: 1.0,
      weightG: 0.0,
      babyMilestones: [
        'The embryo has doubled in size since last week',
        'Hands and feet are paddle-shaped',
        'The digestive system is forming',
      ],
      momTips: [
        'Your uterus has doubled in size — bloating is normal',
        'Mood swings are caused by hormones — talk to your partner',
      ],
      babyImageAsset: '🫐',
      weekHighlight: 'Growing fast — doubled in size this week!',
    ),
    // ── Week 8 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 8,
      fruitEmoji: '🍓',
      fruitName: 'Raspberry',
      sizeCaption: 'About the size of a raspberry',
      lengthCm: 1.6,
      weightG: 1.0,
      babyMilestones: [
        'All major organs are present, though tiny',
        'The baby can move, though you won\'t feel it yet',
        'Webbed fingers are separating into individual digits',
      ],
      momTips: [
        'First ultrasound is usually scheduled around now',
        'Avoid raw fish, unpasteurised cheese, and deli meats',
      ],
      babyImageAsset: '🍓',
      weekHighlight: 'First ultrasound week — you\'ll see baby move!',
    ),
    // ── Week 9 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 9,
      fruitEmoji: '🍇',
      fruitName: 'Grape',
      sizeCaption: 'About the size of a grape',
      lengthCm: 2.3,
      weightG: 2.0,
      babyMilestones: [
        'Tiny toes are forming',
        'The embryo officially becomes a fetus this week',
        'The heart has divided into four chambers',
      ],
      momTips: [
        'Your waistline may start expanding slightly',
        'Keep up prenatal vitamins — iron and folate are critical',
      ],
      babyImageAsset: '🍇',
      weekHighlight: 'From embryo to fetus — a huge milestone.',
    ),
    // ── Week 10 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 10,
      fruitEmoji: '🍓',
      fruitName: 'Strawberry',
      sizeCaption: 'About the size of a strawberry',
      lengthCm: 3.1,
      weightG: 4.0,
      babyMilestones: [
        'Vital organs are fully formed and starting to function',
        'Tiny fingernails are growing',
        'Baby can make small movements',
      ],
      momTips: [
        'First trimester screening blood tests are usually offered now',
        'Heartburn may begin — eat upright and avoid spicy foods',
      ],
      babyImageAsset: '🍓',
      weekHighlight: 'All organs are in place and working.',
    ),
    // ── Week 11 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 11,
      fruitEmoji: '🫛',
      fruitName: 'Fig',
      sizeCaption: 'About the size of a fig',
      lengthCm: 4.1,
      weightG: 7.0,
      babyMilestones: [
        'Baby can open and close fists',
        'Tooth buds are forming beneath the gums',
        'Hiccups may begin (though silent)',
      ],
      momTips: [
        'Nausea often begins to ease in week 11',
        'Light exercise like walking or swimming is beneficial',
      ],
      babyImageAsset: '🫛',
      weekHighlight: 'Baby is making fists — getting stronger.',
    ),
    // ── Week 12 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 12,
      fruitEmoji: '🍋',
      fruitName: 'Lime',
      sizeCaption: 'About the size of a lime',
      lengthCm: 5.4,
      weightG: 14.0,
      babyMilestones: [
        'Reflexes are developing — baby will squirm if prodded',
        'Kidneys start producing urine',
        'The nuchal translucency scan is done this week',
      ],
      momTips: [
        'End of first trimester — miscarriage risk drops significantly',
        'Share your news with family if you haven\'t yet!',
      ],
      babyImageAsset: '🍋',
      weekHighlight: 'End of first trimester 🎉 You made it!',
    ),
    // ── Week 13 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 13,
      fruitEmoji: '🫛',
      fruitName: 'Pea Pod',
      sizeCaption: 'About the size of a pea pod',
      lengthCm: 7.4,
      weightG: 23.0,
      babyMilestones: [
        'Baby\'s fingerprints are forming',
        'Vocal cords are developing',
        'Intestines are moving from the umbilical cord into the abdomen',
      ],
      momTips: [
        'Energy often returns in the second trimester',
        'Start thinking about maternity clothes',
      ],
      babyImageAsset: '🫛',
      weekHighlight: 'Welcome to the second trimester!',
    ),
    // ── Week 14 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 14,
      fruitEmoji: '🍋',
      fruitName: 'Lemon',
      sizeCaption: 'About the size of a lemon',
      lengthCm: 8.7,
      weightG: 43.0,
      babyMilestones: [
        'Baby can squint, frown, and grimace',
        'Sex organs are developing (visible at anomaly scan)',
        'Hair (lanugo) is beginning to grow',
      ],
      momTips: [
        'The "pregnancy glow" often appears now — more blood flow to skin',
        'Round ligament pain (sharp side pains) is normal',
      ],
      babyImageAsset: '🍋',
      weekHighlight: '2nd Trimester — the golden weeks begin.',
    ),
    // ── Week 15 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 15,
      fruitEmoji: '🍊',
      fruitName: 'Orange',
      sizeCaption: 'About the size of a naval orange',
      lengthCm: 10.1,
      weightG: 70.0,
      babyMilestones: [
        'Baby is forming taste buds',
        'Bones are getting harder',
        'Baby can sense light through closed eyelids',
      ],
      momTips: [
        'You may feel the first fluttery movements soon',
        'Stay hydrated — aim for 8-10 glasses daily',
      ],
      babyImageAsset: '🍊',
      weekHighlight: 'First movements (quickening) coming soon!',
    ),
    // ── Week 16 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 16,
      fruitEmoji: '🥑',
      fruitName: 'Avocado',
      sizeCaption: 'About the size of an avocado',
      lengthCm: 11.6,
      weightG: 100.0,
      babyMilestones: [
        'Eyebrows and eyelashes are growing',
        'The nervous system is maturing rapidly',
        'Baby is making breathing movements using amniotic fluid',
      ],
      momTips: [
        'Your bump is now visible — celebrate it!',
        'Consider prenatal yoga or gentle stretching',
      ],
      babyImageAsset: '🥑',
      weekHighlight: 'Your bump is showing — hello, baby bump!',
    ),
    // ── Week 17 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 17,
      fruitEmoji: '🍐',
      fruitName: 'Pear',
      sizeCaption: 'About the size of a pear',
      lengthCm: 13.0,
      weightG: 140.0,
      babyMilestones: [
        'Fat is beginning to form under the skin',
        'Baby can hear your voice',
        'The umbilical cord is growing stronger',
      ],
      momTips: [
        'Talk and sing to your baby — they can hear you!',
        'Sleep on your side (left preferred) for better circulation',
      ],
      babyImageAsset: '🍐',
      weekHighlight: 'Baby can hear your voice for the first time.',
    ),
    // ── Week 18 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 18,
      fruitEmoji: '🫑',
      fruitName: 'Bell Pepper',
      sizeCaption: 'About the size of a bell pepper',
      lengthCm: 14.2,
      weightG: 190.0,
      babyMilestones: [
        'Baby is yawning and hiccupping',
        'Unique fingerprints are now complete',
        'Myelin (nerve insulation) is forming in the brain',
      ],
      momTips: [
        'Anomaly scan (20-week scan) is coming up — prepare questions',
        'Backache is common — a pregnancy pillow can help',
      ],
      babyImageAsset: '🫑',
      weekHighlight: 'Hiccups! Baby is practicing breathing.',
    ),
    // ── Week 19 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 19,
      fruitEmoji: '🥭',
      fruitName: 'Mango',
      sizeCaption: 'About the size of a mango',
      lengthCm: 15.3,
      weightG: 240.0,
      babyMilestones: [
        'Vernix caseosa (protective waxy coating) is forming',
        'Baby is developing a regular sleep/wake cycle',
        'Sensory development is in full swing',
      ],
      momTips: [
        'You should feel baby kicks regularly now',
        'Leg cramps at night are common — stretch before bed',
      ],
      babyImageAsset: '🥭',
      weekHighlight: 'Baby sleeps and wakes just like you.',
    ),
    // ── Week 20 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 20,
      fruitEmoji: '🍌',
      fruitName: 'Banana',
      sizeCaption: 'About the size of a banana',
      lengthCm: 25.6,
      weightG: 300.0,
      babyMilestones: [
        'Halfway there! Baby is fully proportioned',
        'The anomaly scan reveals gender if desired',
        'Baby swallows amniotic fluid and produces urine',
      ],
      momTips: [
        'Halfway milestone — take a belly photo to remember this moment',
        'Discuss birth plan options with your midwife',
      ],
      babyImageAsset: '🍌',
      weekHighlight: '🎉 Halfway there! 20 weeks down, 20 to go.',
    ),
    // ── Week 21 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 21,
      fruitEmoji: '🥕',
      fruitName: 'Carrot',
      sizeCaption: 'About the size of a large carrot',
      lengthCm: 26.7,
      weightG: 360.0,
      babyMilestones: [
        'Baby\'s movements are becoming more coordinated',
        'Eyebrows are fully formed',
        'The liver and spleen are producing blood cells',
      ],
      momTips: [
        'Kick counting: aim to feel 10 movements in 2 hours',
        'Swollen ankles are normal — elevate feet when resting',
      ],
      babyImageAsset: '🥕',
      weekHighlight: 'Baby is moving like a pro athlete.',
    ),
    // ── Week 22 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 22,
      fruitEmoji: '🌽',
      fruitName: 'Corn',
      sizeCaption: 'About the size of a corn cob',
      lengthCm: 27.8,
      weightG: 430.0,
      babyMilestones: [
        'Baby looks like a miniature newborn now',
        'The pancreas is producing hormones',
        'Lips, eyelids, and eyebrows are distinct',
      ],
      momTips: [
        'Start researching cord blood banking if interested',
        'Stretch marks may appear — coconut oil or shea butter can help',
      ],
      babyImageAsset: '🌽',
      weekHighlight: 'Baby looks like a real newborn in miniature.',
    ),
    // ── Week 23 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 23,
      fruitEmoji: '🍆',
      fruitName: 'Eggplant',
      sizeCaption: 'About the size of a small eggplant',
      lengthCm: 28.9,
      weightG: 501.0,
      babyMilestones: [
        'Baby can recognise your voice and partner\'s voice',
        'Lungs are developing air sacs (alveoli)',
        'Baby weighs just over 500g',
      ],
      momTips: [
        'Braxton Hicks contractions (practice contractions) may begin',
        'Take a childbirth class if you haven\'t booked one',
      ],
      babyImageAsset: '🍆',
      weekHighlight: 'Baby recognises your voice — keep talking!',
    ),
    // ── Week 24 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 24,
      fruitEmoji: '🌽',
      fruitName: 'Ear of Corn',
      sizeCaption: 'About the size of an ear of corn',
      lengthCm: 30.0,
      weightG: 600.0,
      babyMilestones: [
        'Viability milestone — baby could survive if born now with care',
        'Inner ear is fully developed — baby has a sense of balance',
        'Taste buds are mature and responding to amniotic fluid',
      ],
      momTips: [
        'Glucose tolerance test is usually offered around week 24-28',
        'Start planning your hospital bag',
      ],
      babyImageAsset: '🌽',
      weekHighlight: 'Viability milestone — a major moment.',
    ),
    // ── Week 25 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 25,
      fruitEmoji: '🥦',
      fruitName: 'Cauliflower',
      sizeCaption: 'About the size of a head of cauliflower',
      lengthCm: 34.6,
      weightG: 660.0,
      babyMilestones: [
        'Baby\'s hands are fully developed',
        'Fat is depositing rapidly, filling out the skin',
        'The startle reflex is developing',
      ],
      momTips: [
        'Shortness of breath is normal — your uterus is pressing on lungs',
        'Stay active but rest more frequently',
      ],
      babyImageAsset: '🥦',
      weekHighlight: 'Baby is plumping up and getting strong.',
    ),
    // ── Week 26 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 26,
      fruitEmoji: '🥬',
      fruitName: 'Kale',
      sizeCaption: 'About the size of a head of kale',
      lengthCm: 35.6,
      weightG: 760.0,
      babyMilestones: [
        'Eyes can open for the first time',
        'Baby responds to touch — press gently and baby may respond',
        'Brain wave activity is similar to a newborn\'s',
      ],
      momTips: [
        'Eyes open! Try shining a light on your belly',
        'Carpal tunnel syndrome is common — wear a wrist brace if needed',
      ],
      babyImageAsset: '🥬',
      weekHighlight: 'Eyes open! Baby can see light and shadow.',
    ),
    // ── Week 27 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 27,
      fruitEmoji: '🥦',
      fruitName: 'Head of Broccoli',
      sizeCaption: 'About the size of a head of broccoli',
      lengthCm: 36.6,
      weightG: 875.0,
      babyMilestones: [
        'Baby is practising breathing movements regularly',
        'The immune system is developing rapidly',
        'Sleep patterns are becoming more distinct',
      ],
      momTips: [
        'Last week of second trimester — the third trimester begins next week',
        'Consider perineal massage to prepare for birth',
      ],
      babyImageAsset: '🥦',
      weekHighlight: 'Last week of 2nd trimester — almost there!',
    ),
    // ── Week 28 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 28,
      fruitEmoji: '🍆',
      fruitName: 'Large Eggplant',
      sizeCaption: 'About the size of a large eggplant',
      lengthCm: 37.6,
      weightG: 1005.0,
      babyMilestones: [
        'Baby now weighs over 1kg — a huge milestone',
        'Eyes can now blink',
        'Brain is developing rapid folds and grooves',
      ],
      momTips: [
        'Third trimester begins — antenatal visits become more frequent',
        'Anti-D injection offered to Rhesus negative mothers',
      ],
      babyImageAsset: '🍆',
      weekHighlight: '3rd Trimester begins — the final stretch! 💪',
    ),
    // ── Week 29 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 29,
      fruitEmoji: '🎃',
      fruitName: 'Small Butternut Squash',
      sizeCaption: 'About the size of a butternut squash',
      lengthCm: 38.6,
      weightG: 1153.0,
      babyMilestones: [
        'Bones are fully formed but still soft',
        'Baby is gaining about 200g per week now',
        'Muscle tone is developing rapidly',
      ],
      momTips: [
        'Kick counting is now important — aim 10 kicks in 2 hours',
        'Sleeping is harder — try a pregnancy pillow between your knees',
      ],
      babyImageAsset: '🎃',
      weekHighlight: 'Baby gains 200g every week from now on.',
    ),
    // ── Week 30 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 30,
      fruitEmoji: '🥥',
      fruitName: 'Coconut',
      sizeCaption: 'About the size of a coconut',
      lengthCm: 39.9,
      weightG: 1319.0,
      babyMilestones: [
        'Lanugo (soft hair) is beginning to shed',
        'Baby\'s brain continues developing billions of connections',
        'Red blood cell production is now done by the bone marrow',
      ],
      momTips: [
        'Heartburn intensifies — sleep propped up',
        'Pack your hospital bag this week',
      ],
      babyImageAsset: '🥥',
      weekHighlight: 'Only 10 more weeks — start your hospital bag.',
    ),
    // ── Week 31 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 31,
      fruitEmoji: '🥥',
      fruitName: 'Coconut',
      sizeCaption: 'About the size of a large coconut',
      lengthCm: 41.1,
      weightG: 1502.0,
      babyMilestones: [
        'Baby can process information from all five senses',
        'Lungs are almost fully mature',
        'Baby may have settled into a head-down position',
      ],
      momTips: [
        'Frequent urination returns as baby drops into pelvis',
        'Check your breast for colostrum — it may have started leaking',
      ],
      babyImageAsset: '🥥',
      weekHighlight: 'Lungs almost ready — baby preparing for birth.',
    ),
    // ── Week 32 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 32,
      fruitEmoji: '🥬',
      fruitName: 'Chinese Cabbage',
      sizeCaption: 'About the size of a Chinese cabbage',
      lengthCm: 42.4,
      weightG: 1702.0,
      babyMilestones: [
        'Toenails and fingernails are fully grown',
        'Skin is becoming less wrinkled as fat fills it out',
        'Baby practices swallowing colostrum-like fluid',
      ],
      momTips: [
        'Pelvic pressure and back pain increase — a support band helps',
        'Discuss your birth preferences with your midwife in detail',
      ],
      babyImageAsset: '🥬',
      weekHighlight: 'Baby is almost fully formed — just growing now.',
    ),
    // ── Week 33 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 33,
      fruitEmoji: '🍍',
      fruitName: 'Pineapple',
      sizeCaption: 'About the size of a pineapple',
      lengthCm: 43.7,
      weightG: 1918.0,
      babyMilestones: [
        'Baby\'s immune system is receiving antibodies from you',
        'Skull bones are still soft and flexible for birth',
        'Baby can detect rhythms and may prefer certain music',
      ],
      momTips: [
        'Braxton Hicks contractions may feel stronger — time them',
        'Install the car seat and practise using it this week',
      ],
      babyImageAsset: '🍍',
      weekHighlight: 'Your antibodies are protecting baby.',
    ),
    // ── Week 34 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 34,
      fruitEmoji: '🎃',
      fruitName: 'Cantaloupe',
      sizeCaption: 'About the size of a cantaloupe',
      lengthCm: 45.0,
      weightG: 2146.0,
      babyMilestones: [
        'Central nervous system and lungs are nearly mature',
        'Baby\'s layers of fat are thickening',
        'Most babies are head-down in position for birth',
      ],
      momTips: [
        'If you haven\'t already, choose a paediatrician',
        'Swelling (oedema) in hands and feet is very common — rest with feet elevated',
      ],
      babyImageAsset: '🎃',
      weekHighlight: 'Baby is in position — head down, ready to go.',
    ),
    // ── Week 35 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 35,
      fruitEmoji: '🍈',
      fruitName: 'Honeydew Melon',
      sizeCaption: 'About the size of a honeydew melon',
      lengthCm: 46.2,
      weightG: 2383.0,
      babyMilestones: [
        'Kidneys are fully developed',
        'Liver can process some waste products',
        'Baby is running out of room — movements feel different',
      ],
      momTips: [
        'Know the signs of labour — contractions 5 min apart lasting 1 min',
        'Pre-eclampsia check at every visit now — report headaches or visual changes immediately',
      ],
      babyImageAsset: '🍈',
      weekHighlight: '5 weeks to go — baby is almost ready!',
    ),
    // ── Week 36 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 36,
      fruitEmoji: '🥬',
      fruitName: 'Head of Romaine',
      sizeCaption: 'About the size of a head of romaine',
      lengthCm: 47.4,
      weightG: 2622.0,
      babyMilestones: [
        '"Lightening" — baby drops lower into the pelvis',
        'Cheeks are now chubby with fat',
        'Lanugo has mostly shed — baby is looking like a newborn',
      ],
      momTips: [
        'You may breathe easier as baby drops — but more toilet trips',
        'Group B strep test is usually done this week',
      ],
      babyImageAsset: '🥬',
      weekHighlight: 'Baby drops — breathing gets easier.',
    ),
    // ── Week 37 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 37,
      fruitEmoji: '🫚',
      fruitName: 'Winter Melon',
      sizeCaption: 'About the size of a winter melon',
      lengthCm: 48.6,
      weightG: 2859.0,
      babyMilestones: [
        'Considered "early term" — all systems are go',
        'Baby is practising sucking and swallowing',
        'The grasping reflex is strong',
      ],
      momTips: [
        'Watch for mucus plug loss — labour may begin soon',
        'Rest as much as possible — save your energy for labour',
      ],
      babyImageAsset: '🫚',
      weekHighlight: 'Early term — baby is ready to meet you!',
    ),
    // ── Week 38 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 38,
      fruitEmoji: '🎃',
      fruitName: 'Small Pumpkin',
      sizeCaption: 'About the size of a small pumpkin',
      lengthCm: 49.8,
      weightG: 3083.0,
      babyMilestones: [
        'Brain and lungs continue to mature until birth',
        'Baby has a firm grasp reflex',
        'Vocal cords are ready for that first cry',
      ],
      momTips: [
        'Pelvic pain and pressure are intense — this is normal',
        'Have your hospital bag at the door',
      ],
      babyImageAsset: '🎃',
      weekHighlight: 'Full term in 2 weeks — any day now.',
    ),
    // ── Week 39 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 39,
      fruitEmoji: '🍉',
      fruitName: 'Small Watermelon',
      sizeCaption: 'About the size of a small watermelon',
      lengthCm: 50.7,
      weightG: 3288.0,
      babyMilestones: [
        'Baby is considered full term',
        'Brain development will continue for years after birth',
        'The outer layer of skin is shed and replaced in the womb',
      ],
      momTips: [
        'Call your midwife if waters break or contractions are regular',
        'Rest and keep yourself calm — you\'ve got this!',
      ],
      babyImageAsset: '🍉',
      weekHighlight: 'Full term! Baby can arrive any moment.',
    ),
    // ── Week 40 ──────────────────────────────────────────────
    PregnancyWeekInfo(
      week: 40,
      fruitEmoji: '🍉',
      fruitName: 'Watermelon',
      sizeCaption: 'About the size of a watermelon',
      lengthCm: 51.2,
      weightG: 3462.0,
      babyMilestones: [
        'Baby is fully developed and ready for the world',
        'Baby\'s skull plates will overlap slightly during birth (moulding)',
        'Baby has about a pint of amniotic fluid surrounding them',
      ],
      momTips: [
        'Your due date is here — but only 5% of babies arrive exactly on time',
        'If no labour by week 41-42, induction will be discussed',
      ],
      babyImageAsset: '🍉',
      weekHighlight: '🎉 Due date! Your baby is ready to be born.',
    ),
  ];
}