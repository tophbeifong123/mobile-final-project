---
name: Retro Neo-Brutalist EdTech
colors:
  surface: '#fbf8fc'
  surface-dim: '#dcd9dd'
  surface-bright: '#fbf8fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f2f7'
  surface-container: '#f0edf1'
  surface-container-high: '#eae7eb'
  surface-container-highest: '#e4e1e6'
  on-surface: '#1b1b1e'
  on-surface-variant: '#464555'
  inverse-surface: '#303033'
  inverse-on-surface: '#f3f0f4'
  outline: '#777587'
  outline-variant: '#c7c4d8'
  surface-tint: '#4d44e3'
  primary: '#3525cd'
  on-primary: '#ffffff'
  primary-container: '#4f46e5'
  on-primary-container: '#dad7ff'
  inverse-primary: '#c3c0ff'
  secondary: '#695f02'
  on-secondary: '#ffffff'
  secondary-container: '#f2e580'
  on-secondary-container: '#6f650a'
  tertiary: '#214e61'
  on-tertiary: '#ffffff'
  tertiary-container: '#3b6679'
  on-tertiary-container: '#b6e2f9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e2dfff'
  primary-fixed-dim: '#c3c0ff'
  on-primary-fixed: '#0f0069'
  on-primary-fixed-variant: '#3323cc'
  secondary-fixed: '#f2e580'
  secondary-fixed-dim: '#d5c867'
  on-secondary-fixed: '#201c00'
  on-secondary-fixed-variant: '#4f4800'
  tertiary-fixed: '#bee9ff'
  tertiary-fixed-dim: '#a1cde3'
  on-tertiary-fixed: '#001f2a'
  on-tertiary-fixed-variant: '#1e4c5f'
  background: '#fbf8fc'
  on-background: '#1b1b1e'
  surface-variant: '#e4e1e6'
  paper-canvas: '#FDF8EE'
  surface-cream: '#FFFBEB'
  pure-white: '#FFFFFF'
  ink-solid: '#18181B'
  subtle-ink: '#4B5563'
  muted-ink: '#9CA3AF'
  butter-yellow: '#FEF08A'
  sky-blue: '#BAE6FD'
  pastel-coral: '#FDBA74'
  soft-lilac: '#DDD6FE'
  fresh-mint: '#A7F3D0'
  soft-rose: '#FDA4AF'
  electric-indigo: '#4F46E5'
typography:
  headline-xl:
    fontFamily: Bricolage Grotesque
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Bricolage Grotesque
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 32px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Bricolage Grotesque
    fontSize: 22px
    fontWeight: '800'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Bricolage Grotesque
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '500'
    lineHeight: 22px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 19px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '700'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '800'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 12px
  margin: 16px
  space-xs: 4px
  space-sm: 8px
  space-md: 12px
  space-lg: 16px
  space-xl: 24px
---

## Brand & Style

This design system blends **Retro-Chunky Neo-Brutalism** with **Playful Illustrated EdTech**, targeted directly at Gen-Z university students navigating internships alongside progressive tech and startup recruiters.

### Visual Character
- **Tactile Print & Zine Metaphor:** Rooted in warm, unbleached paper textures (`#FDF8EE`) paired with solid, deep carbon ink outlines (`#18181B`) at deliberate 2px to 2.5px stroke weights.
- **Graphic Depth without Blur:** Rejects ethereal, translucent blur stacks and gradient glows. Instead, physical hard-edge drop shadows (`3px 3px 0px #18181B`) simulate die-cut paper, physical stickers, and classic graphic print stamps.
- **Playful Pop Accents:** High-vibrancy pastel highlights (Butter Yellow, Soft Mint, Electric Indigo, Coral Peach, Lilac) provide instant visual scaffolding, color-coding critical recruitment metadata like stipend compensation, application states, and skill pills.
- **Expressive Contrast:** Combining oversized, expressive display serif lettering for welcoming titles with utilitarian, ultra-clean geometric sans-serif for numbers, job requirements, and high-density form fields.

## Colors

The color architecture enforces clear semantic roles while preserving a warm, vintage publication aesthetic.

### Palette Architecture
- **Canvas & Surface Tier:**
  - `paper-canvas` (`#FDF8EE`): Serves as the global backdrop, establishing a warm, non-glare reading environment reminiscent of risograph zines.
  - `surface-cream` (`#FFFBEB`): Used for elevated sheets, sticky header zones, and nested secondary cards.
  - `pure-white` (`#FFFFFF`): Reserved exclusively for primary actionable surfaces, job cards, and interactive text input fields.
- **Line & Ink Foundation:**
  - `ink-solid` (`#18181B`): The non-negotiable structural anchor used for all borders (2px–2.5px), primary display typography, and hard cast shadows.
  - `subtle-ink` (`#4B5563`): For metadata, company locations, and secondary captions.
  - `muted-ink` (`#9CA3AF`): For input placeholder text and inactive tab elements.
- **Functional Accents:**
  - `electric-indigo` (`#4F46E5`): Primary call-to-action color, representing tech confidence and primary progression actions.
  - `butter-yellow` (`#FEF08A`): Prominent highlight accent for compensation tags, stipend callouts, and search triggers.
  - `fresh-mint` (`#A7F3D0`): Signals positive progress, high match percentage, and active offer states.
  - `pastel-coral` (`#FDBA74`): Used for creative domain badges, warning alerts, and pending review stages.
  - `sky-blue` (`#BAE6FD`) & `soft-lilac` (`#DDD6FE`): Differentiate categories, technical disciplines, and interview stage tags.
  - `soft-rose` (`#FDA4AF`): Flags destructive actions, rejected stages, or expired roles without aggressive visual alarm.

## Typography

The typography pairs expressive, character-rich headlines with an ergonomic, highly legible sans-serif for UI density.

- **Display & Section Titles (`Bricolage Grotesque`):** Features vintage warmth, bold weight, and playful curves. Ideal for large welcoming salutations (e.g., "Hello David 👋", "Applied", "Post a Role"), giving the interface an artisanal, approachable zine character.
- **Interface & Operational Text (`Plus Jakarta Sans`):** Delivers clean readability across mobile viewports for compensation metrics, company profiles, bulleted job requirements, and status tags.
- **Hierarchy & Microcopy Rules:**
  - Micro tags, pill badges, and form labels leverage `label-sm` or `label-md` with `800` weight and uppercase tracking to maximize scannability at tiny sizes.
  - Numbers and currency figures (such as `$800/Mo` or `20K`) adopt `headline-md` or `headline-sm` with `800` weight for immediate visual parsing.

## Layout & Spacing

This design system is optimized for mobile-first single-column ergonomics (`390px` baseline width, expanding up to `448px` max container width).

### Layout & Rhythm
- **Canvas Margins:** Fixed `16px` outer canvas margins protect content from screen edges and accommodate device borders.
- **Grid Architecture:** 
  - Standard cards and content streams span the full available width (1-column layout).
  - Quick-action stat blocks, candidate metric grids, and promo category cards utilize a 2-column balanced grid with a fixed `12px` gutter.
- **Vertical Rhythm:**
  - `space-xs` (4px): Inline pill badge padding and icon-to-text gaps.
  - `space-sm` (8px): Distance between metadata rows within cards.
  - `space-md` (12px): Padding inside pill badges, compact inputs, and list row dividers.
  - `space-lg` (16px): Internal padding for neo-cards, hero headers, and sticky bottom navigation containers.
  - `space-xl` (24px): Vertical spacing separating independent content blocks (e.g., promotional banner carousel to recent jobs list).
- **Safe Area Insets:** Sticky bottom interaction sheets enforce `pb-20` (80px bottom clearing) to prevent overlap with native iOS Home Indicators and Android navigation bars.

## Elevation & Depth

Visual hierarchy does not rely on opacity or Gaussian blurs. Instead, depth is rendered purely through **tactile hard-offset neo-brutalist shadows** and **crisp dark borders**.

### Physical Elevation Matrix
1. **Level 0 (Flat Ground):**
   - Canvas background (`#FDF8EE`). No shadow. Borderless or single separator lines.
2. **Level 1 (Pills, Chips, Mini Buttons):**
   - Border: `1.5px solid #18181B`
   - Shadow: `1.5px 1.5px 0px #18181B`
3. **Level 2 (Standard Interactive Cards, Inputs, Buttons):**
   - Border: `2.5px solid #18181B`
   - Shadow: `3px 3px 0px #18181B`
4. **Level 3 (Modal Sheets, Floats, Dev Bar, Hero Banners):**
   - Border: `2.5px solid #18181B`
   - Shadow: `5px 5px 0px #18181B`

### Tactile Feedback (Active & Tap States)
To mimic physical micro-switches:
- On tap / `:active`, an element physically depresses: `transform: translate(2px, 2px)`.
- Simultaneously, its shadow collapses from `3px 3px 0px #18181B` down to `1px 1px 0px #18181B`.
- This tactile response gives every interactive component an immediate mechanical spring feel.

## Shapes

The design system employs a **rounded neo-brutal** approach that balances high-contrast blockiness with warm, playful corner radii.

### Curvature Hierarchy
- **Standard Corners (`0.5rem` / `8px` to `12px`):** Used on inner elements like icon badges, dropdown boxes, and small thumbnail media containers.
- **Containers & Neo-Cards (`1rem` / `16px`):** Used on job cards, candidate profile containers, and metric summary boxes. Softens the aggressive 2.5px black outline, lending a warm, approachable character.
- **Pills & Status Tags (`9999px` / Full Pill):** Applied to filter chips (`All`, `Full time`, `Hybrid`), category pills, stipend badges, and notification counters.
- **Input Fields (`0.75rem` / `12px`):** Soft enough to distinguish typing areas, reinforced with deep black borders.

## Components

### Buttons
- **Primary Action Button:** Background is `electric-indigo` (`#4F46E5`) with pure white text (`#FFFFFF`), `2.5px solid #18181B` border, and `3px 3px 0px #18181B` drop shadow. `font-weight: 700`, `height: 48px`, `border-radius: 12px`.
- **Secondary / Quick Filter Button:** Background is `surface-cream` (`#FFFBEB`) or `butter-yellow` (`#FEF08A`) with `ink-solid` (`#18181B`) text. Border and shadow match primary button specs.
- **Icon Square Button (e.g. Bookmark, Share, Back):** `44px x 44px` square, `border-radius: 12px`, `2.5px solid #18181B`, `3px 3px 0px #18181B`. Active state translates by `2px 2px`.

### Cards & Items (`NeoCard`)
- **Container:** Pure white background (`#FFFFFF`), `2.5px solid #18181B`, `rounded-2xl` (16px), hard shadow `3px 3px 0px #18181B`.
- **Card Structure:**
  - Header with `40px x 40px` rounded brand avatar encased in a `1.5px solid #18181B` outline.
  - Bold job title (`headline-sm`) followed by subtle company name (`subtle-ink`).
  - Footer row highlighting stipend badge (`butter-yellow` pill) alongside location metadata.
  - Top-right shortcut action (Bookmark outline or status chip).

### Chips & Badges
- **Status Badges:** 
  - `Reviewed / Accepted`: `fresh-mint` (`#A7F3D0`), border `1.5px solid #18181B`.
  - `Review / Pending`: `pastel-coral` (`#FDBA74`) or `soft-rose` (`#FDA4AF`), border `1.5px solid #18181B`.
  - `Stipend Tag`: `butter-yellow` (`#FEF08A`), bold font weight.
- **Category Filter Scroller:** Full pill shape (`rounded-full`), white or pastel background, `1.5px solid #18181B`. Selected state flips background to `ink-solid` with white text or pops with `butter-yellow`.

### Form Controls & Inputs
- **Search Bar:** Height `48px`, background `pure-white` (`#FFFFFF`), border `2.5px solid #18181B`, hard shadow `2.5px 2.5px 0px #18181B`. Leading magnifying glass icon encased in soft lilac or butter yellow rounded square.
- **Text Inputs & Textareas:** `pure-white` surface, `2px solid #18181B`, `rounded-xl`. On focus, shifts to a light warm tint (`#FEF08A` at 15% opacity) while retaining a crisp `#18181B` border.

### Sticky Bottom Navigation & Action Bars
- **Navigation Bar:** Fixed bottom container, `surface-cream` backing, top border `2.5px solid #18181B`. Contains 3 to 4 pill items (`Home`, `Applied`, `Profile`) with active items adopting a hard outline pill highlight.
- **Detail Action Drawer:** Pinned at bottom of the viewport with a dual layout: an icon-only square button (`Bookmark`) alongside an expansive `flex-1` width CTA button (`Apply Now 🚀`).

### Stepper Timeline (Application Tracking)
- Vertical or horizontal segmented nodes connected by solid `2.5px` ink paths.
- Completed steps feature `fresh-mint` circle indicators with black outlines.
- Current active step features an oversized bouncing pill marker with `butter-yellow` accent.