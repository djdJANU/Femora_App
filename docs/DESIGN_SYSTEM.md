# FEMORA DESIGN SYSTEM

This document defines all UI tokens and layout rules.
No UI should use hardcoded values.

---

## 1. Color Tokens

### Primary Palette

Primary: #A66CFF  
Primary Dark: #8F4DFF  
Primary Light: #C59DFF  

### Secondary / Accent

Lavender Whisper: #E9D8FD  
Soft Lilac: #D8B4FE  
Light Background Tint: #F6F0FF  

### Text Colors

Text Primary: #1A1A1A  
Text Secondary: #6B7280  
Text Light: #FFFFFF  

### Semantic

Success: #22C55E  
Warning: #F59E0B  
Error: #EF4444  

---

## 2. Spacing System (8pt Grid)

Spacing values must follow 8pt rule:

4   → xs  
8   → sm  
16  → md  
24  → lg  
32  → xl  
40  → xxl  
48  → xxxl  

Use constants only.
No random spacing values allowed.

---

## 3. Typography Scale (Nunito)

Font Family: Nunito

Display Large: 38 / Bold  
Headline Large: 28 / SemiBold  
Headline Medium: 22 / SemiBold  
Title Large: 18 / Medium  
Body Large: 16 / Regular  
Body Medium: 14 / Regular  
Caption: 12 / Regular  

---

## 4. Border Radius

Small: 8  
Medium: 16  
Large: 24  
Circular UI elements: 999  

---

## 5. Elevation

Level 1 → subtle shadow  
Level 2 → moderate  
Level 3 → elevated cards  

---

## 6. Animation Timing

Fast: 150ms  
Normal: 300ms  
Slow: 600ms  

Curves:
- easeOut
- easeOutBack
- easeInOut

---

## 7. Layout Principles

- Always use 8pt grid.
- Center major brand elements.
- Avoid overuse of shadows.
- Purple gradients should be subtle.
- Logo spacing must follow grid system.
- No hardcoded pixel values unless tokenized.

---

## 8. Splash Screen Rules

Background: Primary  
Logo circle: white @ 18% opacity  
Logo emoji: centered  
App title: Nunito ExtraBold  
Subtitle: white @ 78% opacity  
Fade + scale animation: 900ms  

---

End of Design System