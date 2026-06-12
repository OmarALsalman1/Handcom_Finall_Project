from __future__ import annotations

import math
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
from typing import Optional


# ── Problem Analysis dataclass ────────────────────────────────────────────────

@dataclass
class ProblemAnalysis:
    service_category: str   # one of VALID_SERVICE_CATEGORIES
    severity: str           # 'simple' | 'needs_provider'
    summary: str            # Arabic conversational response to show the user
    direct_solution: Optional[str]
    confidence: float       # 0.0 – 1.0
    needs_clarification: bool = False  # True while the AI is still asking about the problem

    def to_dict(self):
        return asdict(self)


# ── Arabic category labels ────────────────────────────────────────────────────

_CATEGORY_ARABIC = {
    'plumbing':   'السباكة',
    'electrical': 'الكهرباء',
    'painting':   'الدهان',
    'carpentry':  'النجارة',
}

# ── Rule-based classification data ───────────────────────────────────────────

_CATEGORY_KEYWORDS: dict = {
    'plumbing':         ['pipe', 'leak', 'water', 'faucet', 'drain', 'toilet',
                         'shower', 'plumb', 'tap', 'sink', 'burst', 'flood',
                         'سباك', 'تسرب', 'مياه', 'حنفية', 'بالوعة', 'مرحاض',
                         'دش', 'غسالة أطباق', 'ماء', 'ضغط الماء', 'سباكة',
                         'تمديد', 'أنابيب', 'خزان ماء', 'خزان المياه', 'تسريب مياه'],
    'electrical':       ['electric', 'wiring', 'outlet', 'switch', 'power',
                         'light', 'circuit', 'breaker', 'socket', 'voltage', 'wire',
                         'كهرباء', 'كهربائي', 'قاطع', 'مقبس', 'إضاءة', 'تمديدات',
                         'لمبة', 'سلك', 'شبكة كهرباء', 'توصيلات', 'لوحة', 'تيار'],
    'painting':         ['paint', 'wall', 'color', 'colour', 'brush', 'stain',
                         'coat', 'repaint', 'peel', 'peeling',
                         'دهان', 'طلاء', 'جدار', 'لون', 'سقف', 'ديكور', 'تشقق'],
    'carpentry':        ['wood', 'door', 'window', 'cabinet', 'shelf',
                         'furniture', 'hinge', 'lock', 'carpenter', 'timber',
                         'نجار', 'خشب', 'باب', 'شباك', 'نافذة', 'خزانة', 'مطبخ',
                         'أثاث', 'مفصلة', 'قفل', 'رف'],
}

_SIMPLE_SOLUTIONS_AR: dict = {
    'plumbing': [
        (['dripping faucet', 'dripping tap', 'drip', 'تقطير', 'يقطر'],
         'يمكنك إحكام ربط صمام الحنفية أو استبدال الواشر الداخلي التالف. هذا حل بسيط يمكنك القيام به بنفسك!'),
        (['clogged drain', 'slow drain', 'blocked drain', 'clogged sink', 'انسداد', 'بطيء', 'مسدود'],
         'استخدم أداة شد الانسدادات (المص). يمكنك أيضاً صب مزيج من بيكربونات الصودا والخل، انتظر 30 دقيقة ثم اشطف بالماء الساخن.'),
        (['clogged toilet', 'مرحاض مسدود', 'مرحاض لا ينزل'],
         'جرّب استخدام أداة شد الانسدادات (المص) عدة مرات بضغط ثابت. إذا لم تنجح، صب دلواً من الماء الساخن (وليس المغلي) من ارتفاع لمساعدة الدفع.'),
        (['running toilet', 'toilet keeps running', 'مرحاض يسرب', 'صندوق الطرد يسرب'],
         'افتح غطاء صندوق الطرد وتأكد أن السدادة المطاطية (الفلاب) تغلق بإحكام، أو اضبط ذراع العوامة — غالباً المشكلة بسيطة وقابلة للتعديل يدوياً.'),
        (['low water pressure', 'ضعف الضغط', 'ضغط الماء ضعيف'],
         'افحص رأس الحنفية أو الدش وانقعه في الخل لإزالة ترسبات الكلس التي تسد الفتحات الصغيرة.'),
    ],
    'electrical': [
        (['tripped breaker', 'circuit breaker', 'قاطع', 'انطفأ الكهرباء'],
         'ابحث عن لوحة الكهرباء الرئيسية وأعد تشغيل القاطع الذي انطفأ بتحريكه نحو "إيقاف" ثم "تشغيل".'),
        (['flickering light', 'flickering bulb', 'لمبة', 'وميض'],
         'تأكد من أن اللمبة محكمة الربط. جرب استبدالها بلمبة أخرى أولاً.'),
        (['outlet not working', 'socket not working', 'مقبس لا يعمل', 'مقبس معطل'],
         'جرب توصيل جهاز آخر بنفس المقبس للتأكد أن المشكلة فيه، وتحقق من قاطع الدائرة الخاص به في لوحة الكهرباء.'),
    ],
    'carpentry': [
        (['loose screw', 'loose hinge', 'مفصلة', 'برغي'],
         'شد البراغي بالمفك المناسب. إذا كان الثقب مفرغاً، أدخل عيدان خشبية مع الصمغ قبل الشد.'),
        (['squeaky door', 'creaking door', 'باب يصدر صرير', 'صرير الباب'],
         'ضع القليل من الزيت أو الشحم على مفصلات الباب وحركه عدة مرات لتوزيعه — يحل المشكلة فوراً غالباً.'),
        (['stuck drawer', 'sticking door', 'درج عالق', 'باب عالق', 'باب لا يغلق',
          'جرار عالق', 'جرار معلق', 'جرار لا يفتح', 'درج لا يفتح', 'درج معلق'],
         'افحص المسارات أو الإطار بحثاً عن غبار أو احتكاك، ونظفها وضع طبقة رقيقة من الشمع أو الصابون الجاف لتسهيل الحركة.'),
    ],
    'painting': [
        (['peeling paint', 'small scratch', 'تقشر بسيط', 'خدوش بسيطة', 'بقعة صغيرة'],
         'نظف المنطقة جيداً، ضع طبقة من المعجون لملء أي فجوات، اصنفرها بعد الجفاف، ثم ضع طبقة دهان مطابقة للون الأصلي.'),
    ],
}

# Cross-category indicators that this is urgent/serious enough that DIY isn't safe —
# even if no specific simple-solution pattern matched, go straight to "needs_provider"
_SEVERE_INDICATORS_AR = [
    'burst', 'flooding', 'flood', 'سيول', 'انفجار', 'انفجر', 'فيضان', 'يغرق',
    'spark', 'sparks', 'شرارة', 'شرر', 'smoke', 'دخان', 'حريق', 'احتراق', 'صعقة',
    'no power', 'no electricity', 'انقطع التيار', 'انقطعت الكهرباء كلياً',
    'gas smell', 'رائحة غاز', 'تسرب غاز',
    'completely broken', 'stopped working completely', 'توقف نهائياً', 'تعطل تماماً',
]


def _has_severe_indicator(text: str) -> bool:
    text_lower = text.lower()
    return any(kw in text_lower for kw in _SEVERE_INDICATORS_AR)


# Explicit asks that must break out of the clarification loop immediately —
# the user is telling us directly what they want, so stop probing for symptoms.
_WANTS_SOLUTION_PHRASES_AR = [
    'حلول', 'حل المشكلة', 'حل لها', 'كيف أحل', 'كيف احل', 'اقترح حل', 'اقترح علي حل',
    'عطني حل', 'أعطني حل', 'وريني حل', 'solution', 'how to fix', 'how do i fix', 'fix it myself',
]
_WANTS_PROVIDER_PHRASES_AR = [
    'فني', 'محترف', 'مختص', 'متخصص', 'حد يصلح', 'شخص يصلح', 'ابغى حد', 'أبغى حد',
    'بدي حد', 'بدها حد', 'provider', 'technician', 'specialist', 'professional',
]


def _wants_solution_now(text_lower: str) -> bool:
    return any(p in text_lower for p in _WANTS_SOLUTION_PHRASES_AR)


def wants_provider_now(text_lower: str) -> bool:
    return any(p in text_lower for p in _WANTS_PROVIDER_PHRASES_AR)


# Phrases that mean "the DIY solution you gave me didn't fix it" — used to
# escalate straight to provider recommendations for the same category.
_NEGATIVE_FEEDBACK_PHRASES_AR = [
    'ما نفع', 'ما نفعت', 'لم ينفع', 'لم تنفع', 'لم تنجح', 'ما نجح', 'ما نجحت',
    'ما اشتغل', 'ما اشتغلت', 'لم يعمل', 'لم تعمل', 'مازال', 'ما زال', 'مازالت',
    'ما زالت', 'لسه نفس المشكلة', 'لسا نفس المشكلة', 'نفس المشكلة', 'لم تحل',
    'مو شغال', 'مش شغال', 'ماضبط', 'ما ضبط', 'مازبط', 'ما زبط', 'لم يفلح',
    "didn't work", 'did not work', "doesn't work", 'does not work',
    'not working', 'still not working', "didn't help", 'did not help',
    "doesn't help", 'no luck', 'still broken', 'still the same',
]


def is_negative_feedback(text_lower: str) -> bool:
    return any(p in text_lower for p in _NEGATIVE_FEEDBACK_PHRASES_AR)


# Generic, category-level fallback tip used when the user explicitly asks for a
# solution but the symptom was too vague to match a specific DIY pattern.
_GENERIC_TIPS_AR = {
    'plumbing': (
        'كحل أولي: أغلق صمام الماء القريب من المشكلة لمنع تفاقمها، وافحص الوصلات '
        'والمواسير الظاهرة بحثاً عن مكان التسرب أو الانسداد — غالباً يكون السبب '
        'وصلة غير محكمة أو حشية تالفة يمكن شدها أو استبدالها بسهولة.'
    ),
    'electrical': (
        'كحل أولي: تحقق من لوحة الكهرباء الرئيسية وتأكد أن القاطع الخاص بالمكان '
        'لم يفصل، وجرب فصل وإعادة توصيل الجهاز أو المفتاح المعطل — لكن لا تفتح '
        'أي تمديدات كهربائية بنفسك إن لم تكن متأكداً، تجنباً لخطر الصعق.'
    ),
    'carpentry': (
        'كحل أولي: افحص المفصلات والمسارات والبراغي — تنظيفها من الغبار، '
        'وضع القليل من الزيت أو الشمع عليها، وإحكام ربط البراغي يحل أغلب '
        'مشاكل الأبواب والأدراج العالقة أو التي تصدر صريراً.'
    ),
    'painting': (
        'كحل أولي: نظف المنطقة المتضررة جيداً، اصنفر الأجزاء المتقشرة برفق، '
        'ثم ضع طبقة معجون رقيقة لتسوية السطح قبل إعادة الدهان بلون مطابق.'
    ),
}

_SIMPLE_SOLUTIONS_EN: dict = {
    'plumbing': [
        (['dripping faucet', 'dripping tap', 'drip', 'تقطير', 'يقطر'],
         'Try tightening the faucet valve or replacing the worn washer inside. This is a simple fix you can do yourself!'),
        (['clogged drain', 'slow drain', 'blocked drain', 'clogged sink', 'انسداد', 'بطيء', 'مسدود'],
         'Use a plunger. You can also pour a mix of baking soda and vinegar, wait 30 minutes, then flush with hot water.'),
        (['clogged toilet', 'مرحاض مسدود', 'مرحاض لا ينزل'],
         "Try using a plunger with firm, steady pressure several times. If that doesn't work, pour a bucket of hot (not boiling) water from a height to help push the clog through."),
        (['running toilet', 'toilet keeps running', 'مرحاض يسرب', 'صندوق الطرد يسرب'],
         'Open the tank lid and check that the rubber flapper seals properly, or adjust the float arm — usually a simple manual adjustment fixes it.'),
        (['low water pressure', 'ضعف الضغط', 'ضغط الماء ضعيف'],
         'Check the faucet or shower head and soak it in vinegar to dissolve mineral deposits blocking the small holes.'),
    ],
    'electrical': [
        (['tripped breaker', 'circuit breaker', 'قاطع', 'انطفأ الكهرباء'],
         'Find your main electrical panel and reset the tripped breaker by flipping it to "off" then back to "on".'),
        (['flickering light', 'flickering bulb', 'لمبة', 'وميض'],
         'Make sure the bulb is screwed in tightly. Try replacing it with a new bulb first.'),
        (['outlet not working', 'socket not working', 'مقبس لا يعمل', 'مقبس معطل'],
         "Plug another device into the same outlet to confirm it's the problem, then check its corresponding breaker in the electrical panel."),
    ],
    'carpentry': [
        (['loose screw', 'loose hinge', 'مفصلة', 'برغي'],
         'Tighten the screws with the right screwdriver. If the hole is stripped, insert wooden toothpicks with wood glue before re-tightening.'),
        (['squeaky door', 'creaking door', 'باب يصدر صرير', 'صرير الباب'],
         'Apply a little oil or grease to the door hinges and move the door back and forth to spread it — usually stops the squeak immediately.'),
        (['stuck drawer', 'sticking door', 'درج عالق', 'باب عالق', 'باب لا يغلق',
          'جرار عالق', 'جرار معلق', 'جرار لا يفتح', 'درج لا يفتح', 'درج معلق'],
         'Check the tracks or frame for dust or friction, clean them, and apply a thin coat of wax or dry soap to help it slide smoothly.'),
    ],
    'painting': [
        (['peeling paint', 'small scratch', 'تقشر بسيط', 'خدوش بسيطة', 'بقعة صغيرة'],
         'Clean the area thoroughly, apply filler to any gaps, sand it smooth after drying, then apply a matching paint color.'),
    ],
}

_GENERIC_TIPS_EN = {
    'plumbing': (
        'As a first step: shut off the water valve near the problem to prevent it getting worse, '
        'then inspect visible pipes and connections for the source — often it\'s just a loose fitting '
        'or worn washer that can be tightened or replaced easily.'
    ),
    'electrical': (
        'As a first step: check your main electrical panel and make sure the breaker for that area '
        'hasn\'t tripped, then try unplugging and reconnecting the device — but do not open any '
        'electrical wiring yourself unless you\'re confident, to avoid shock.'
    ),
    'carpentry': (
        'As a first step: check the hinges, tracks, and screws — cleaning off dust, '
        'applying a little oil or wax, and tightening loose screws fixes most sticky '
        'doors, drawers, and squeaky hinges.'
    ),
    'painting': (
        'As a first step: clean the damaged area, lightly sand any peeling sections, '
        'then apply a thin coat of filler to smooth the surface before repainting with a matching color.'
    ),
}


_NEGATION_WORDS_AR = ['مش', 'مو', 'ليس', 'لا', 'not']


def _negated_categories(text_lower: str) -> set:
    """Detect 'مش سباكة' / 'not plumbing' style corrections so that a user
    ruling a category OUT doesn't get counted as evidence FOR it (the category's
    own Arabic name is also one of its keywords)."""
    negated = set()
    for cat, cat_name_ar in _CATEGORY_ARABIC.items():
        names = {cat_name_ar, cat_name_ar.lstrip('ال'), cat}
        for neg in _NEGATION_WORDS_AR:
            for name in names:
                if name and re.search(re.escape(neg) + r'\s{0,3}' + re.escape(name), text_lower):
                    negated.add(cat)
    return negated


def _classify(text: str):
    """Returns (category, confidence). category is None when no keyword matched —
    the caller must ask a clarifying question rather than guess."""
    text_lower = text.lower()
    negated = _negated_categories(text_lower)
    best_cat, best_count = None, 0
    for cat, keywords in _CATEGORY_KEYWORDS.items():
        if cat in negated:
            continue
        count = sum(1 for kw in keywords if kw in text_lower)
        if count > best_count:
            best_count = count
            best_cat = cat
    if best_cat is None:
        return None, 0.0
    confidence = min(best_count / 3.0, 1.0)
    return best_cat, max(confidence, 0.4)


def _find_simple_solution(text: str, category: str, lang: str = 'ar'):
    solutions = _SIMPLE_SOLUTIONS_EN if lang == 'en' else _SIMPLE_SOLUTIONS_AR
    text_lower = text.lower()
    for patterns, solution in solutions.get(category, []):
        if any(p.lower() in text_lower for p in patterns):
            return solution
    return None


# Appended after a "simple" DIY solution so the user knows they can ask for a
# technician if the suggested fix doesn't solve their problem.
_SOLUTION_FOLLOW_UP_AR = (
    '\n\nهل ساعدك هذا الحل؟ 🙂 إذا لم ينجح معك، أخبرني فقط '
    'وسأقترح عليك أفضل الفنيين المتخصصين في منطقتك.'
)
_SOLUTION_FOLLOW_UP_EN = (
    "\n\nDid this solution help? 🙂 If it didn't work, just let me know "
    "and I'll suggest the best specialists near you."
)


def solution_follow_up(lang: str = 'ar') -> str:
    return _SOLUTION_FOLLOW_UP_EN if lang == 'en' else _SOLUTION_FOLLOW_UP_AR


def build_escalation_analysis(category: str, lang: str = 'ar') -> ProblemAnalysis:
    """Used when the user reports that a previously suggested DIY solution
    didn't fix their problem — escalate straight to provider recommendations
    for the same category instead of re-classifying from scratch."""
    if lang == 'en':
        summary = (
            f"No worries — since that didn't solve it, here are the best "
            f"{category} technicians available near you 👇"
        )
    else:
        cat_ar = _CATEGORY_ARABIC.get(category, category)
        summary = (
            f'لا بأس، بما أن الحل البسيط لم ينفع، إليك أفضل الفنيين '
            f'المتخصصين في {cat_ar} المتوفرين في منطقتك 👇'
        )
    return ProblemAnalysis(
        service_category=category,
        severity='needs_provider',
        summary=summary,
        direct_solution=None,
        confidence=0.9,
        needs_clarification=False,
    )


# ── AIProvider abstraction ────────────────────────────────────────────────────

class AIProvider(ABC):
    @abstractmethod
    def analyze_text(self, text: str, lang: str = 'ar') -> ProblemAnalysis: ...

    def analyze_image_file(self, image_file, lang: str = 'ar') -> ProblemAnalysis:
        return self.analyze_text(f'[صورة لمشكلة في المنزل: {getattr(image_file, "name", "")}]', lang=lang)

    def analyze_voice_file(self, voice_file, lang: str = 'ar') -> ProblemAnalysis:
        if lang == 'en':
            summary = (
                'Voice message received! 🎙️\n\n'
                'For a more accurate analysis, please describe the problem in text '
                'or send a photo and I\'ll help you find the right technician.'
            )
        else:
            summary = (
                'استلمت رسالتك الصوتية! 🎙️\n\n'
                'للحصول على تحليل دقيق، يرجى كتابة وصف المشكلة بالنص '
                'أو إرسال صورة لها وسأساعدك في إيجاد الفني المناسب.'
            )
        return ProblemAnalysis(
            service_category='plumbing',
            severity='needs_provider',
            summary=summary,
            direct_solution=None,
            confidence=0.4,
        )


class RuleBasedAIProvider(AIProvider):
    """Keyword-matching provider — no external API required."""

    def analyze_text(self, text: str, lang: str = 'ar') -> ProblemAnalysis:
        category, confidence = _classify(text)
        text_lower = text.lower()
        wants_solution = _wants_solution_now(text_lower)
        wants_provider = wants_provider_now(text_lower)

        if lang == 'en':
            if category is None:
                return ProblemAnalysis(
                    service_category='',
                    severity='needs_provider',
                    summary=(
                        'Could you clarify a bit more? What type of problem is it exactly '
                        '(plumbing, electrical, painting, or carpentry) and which area? '
                        'That way I can suggest the right technician 🙏'
                    ),
                    direct_solution=None,
                    confidence=0.0,
                    needs_clarification=True,
                )

            cat_label = category
            direct_solution = _find_simple_solution(text, category, lang='en')
            if not direct_solution and wants_solution and not wants_provider:
                direct_solution = _GENERIC_TIPS_EN.get(category)

            if direct_solution:
                return ProblemAnalysis(
                    service_category=category,
                    severity='simple',
                    summary=f'Got it! This looks like a {cat_label} issue — the good news is you can probably fix it yourself 😊 Here\'s what to do:',
                    direct_solution=direct_solution,
                    confidence=confidence,
                    needs_clarification=False,
                )

            if _has_severe_indicator(text):
                return ProblemAnalysis(
                    service_category=category,
                    severity='needs_provider',
                    summary=f'This looks like an urgent {cat_label} situation that needs a professional right away to prevent further damage. Here are the best available technicians nearby 👇',
                    direct_solution=None,
                    confidence=max(confidence, 0.7),
                    needs_clarification=False,
                )

            if wants_provider:
                return ProblemAnalysis(
                    service_category=category,
                    severity='needs_provider',
                    summary=f'Got it — this {cat_label} issue needs a specialist. Here are the best available technicians in your area 👇',
                    direct_solution=None,
                    confidence=max(confidence, 0.6),
                    needs_clarification=False,
                )

            return ProblemAnalysis(
                service_category=category,
                severity='needs_provider',
                summary=(
                    f'I can see this is a {cat_label} issue. To help you better — '
                    f'could you describe exactly what\'s happening? For example, when did it start '
                    f'and is it getting worse? With those details I can tell you whether you can '
                    f'fix it yourself or need a technician 🙏'
                ),
                direct_solution=None,
                confidence=confidence,
                needs_clarification=True,
            )

        # ── Arabic (default) ──────────────────────────────────────────────────
        if category is None:
            return ProblemAnalysis(
                service_category='',
                severity='needs_provider',
                summary=(
                    'ممكن توضح لي أكثر؟ ما هو نوع المشكلة بالضبط '
                    '(سباكة، كهرباء، دهان، أو نجارة) '
                    'وفي أي منطقة تسكن؟ حتى أقدر أقترح عليك الفني الأنسب 🙏'
                ),
                direct_solution=None,
                confidence=0.0,
                needs_clarification=True,
            )

        cat_ar = _CATEGORY_ARABIC.get(category, category)

        direct_solution = _find_simple_solution(text, category, lang='ar')
        if not direct_solution and wants_solution and not wants_provider:
            direct_solution = _GENERIC_TIPS_AR.get(category)

        if direct_solution:
            return ProblemAnalysis(
                service_category=category,
                severity='simple',
                summary=(
                    f'فهمت مشكلتك! يبدو أنها تتعلق بـ{cat_ar}، '
                    f'والخبر السار أنك تستطيع حلها بنفسك 😊 إليك الحل:'
                ),
                direct_solution=direct_solution,
                confidence=confidence,
                needs_clarification=False,
            )

        if _has_severe_indicator(text):
            return ProblemAnalysis(
                service_category=category,
                severity='needs_provider',
                summary=(
                    f'هذه تبدو حالة طارئة في {cat_ar} وتحتاج فنياً متخصصاً فوراً '
                    f'لتفادي أي خطر أو ضرر إضافي. إليك أقرب وأفضل الفنيين المتاحين 👇'
                ),
                direct_solution=None,
                confidence=max(confidence, 0.7),
                needs_clarification=False,
            )

        if wants_provider:
            return ProblemAnalysis(
                service_category=category,
                severity='needs_provider',
                summary=(
                    f'تمام، يبدو أن مشكلة {cat_ar} هذه تحتاج فنياً متخصصاً. '
                    f'إليك أفضل الفنيين المتاحين في منطقتك 👇'
                ),
                direct_solution=None,
                confidence=max(confidence, 0.6),
                needs_clarification=False,
            )

        return ProblemAnalysis(
            service_category=category,
            severity='needs_provider',
            summary=(
                f'فهمت أن المشكلة تتعلق بـ{cat_ar}. حتى أقدر أساعدك بشكل أدق — '
                f'هل يمكنك وصف ما يحدث بالتحديد؟ مثلاً متى بدأت المشكلة وهل تزداد سوءاً؟ '
                f'بهذه التفاصيل أقدر أخبرك إذا كان بإمكانك حلها بنفسك أو تحتاج فنياً 🙏'
            ),
            direct_solution=None,
            confidence=confidence,
            needs_clarification=True,
        )


class GeminiAIProvider(AIProvider):
    """
    Gemini 2.5 Flash — conversational Arabic chatbot for home maintenance.
    Falls back to RuleBasedAIProvider on any API error.
    """

    MODEL = 'models/gemini-2.5-flash-lite'

    def __init__(self):
        from django.conf import settings
        self.api_key = getattr(settings, 'GEMINI_API_KEY', '')
        if not self.api_key:
            raise ValueError('GEMINI_API_KEY is not configured.')
        try:
            from google import genai
            self.client = genai.Client(api_key=self.api_key)
        except ImportError as exc:
            raise ImportError(
                'google-genai is required. Install: pip install google-genai'
            ) from exc

    def analyze_text(self, text: str, lang: str = 'ar') -> ProblemAnalysis:
        lang_instruction = (
            'Respond to the user in English.' if lang == 'en'
            else 'رد على رسالة المستخدم بشكل محادثة طبيعية ودية باللغة العربية.'
        )
        prompt = (
            f'أنت مساعد ذكي ودود متخصص في الصيانة المنزلية تعمل لحساب تطبيق Handcom. '
            f'{lang_instruction}\n\n'

            'التطبيق يدعم 4 تخصصات فقط — استخدم معرفتك لتصنيف المشكلة بذكاء:\n'
            '  • plumbing   (السباكة): مواسير، حنفيات، تسرب مياه، مرحاض، بالوعة، دش، خزان ماء\n'
            '  • electrical (الكهرباء): أسلاك، مقابس، لوحة كهرباء، لمبات، قاطعات، تيار كهربائي\n'
            '  • painting   (الدهان):   دهان جدران، طلاء، تشقق، تقشر دهان، ديكور\n'
            '  • carpentry  (النجارة):  أبواب، نوافذ، خزائن، أدراج، أثاث خشبي، مفصلات، أقفال، '
            'رفوف، كمدينة، كوميدينا، درج، جارور — أي شيء خشبي أو متعلق بالأثاث والأبواب\n\n'

            'اتبع هذا الترتيب بالضبط لتقرر ردك — أول قاعدة تنطبق هي التي تُستخدم، '
            'ولا تطبّق القواعد التي تليها:\n\n'

            '1) إذا كانت الرسالة غامضة تماماً ولا تحمل أي دليل على نوع المشكلة (لا '
            'يمكن تحديد التخصص حتى تخميناً):\n'
            '   service_category="", needs_clarification=true, severity="needs_provider", '
            'direct_solution=null.\n'
            '   summary: اسأله عن نوع المشكلة (سباكة/كهرباء/دهان/نجارة) فقط، لا تذكر فنيين.\n\n'

            '2) إذا كانت المشكلة خطيرة أو عاجلة (تسرب كبير/فيضان، شرارة أو صعقة كهربائية، '
            'رائحة غاز، انقطاع كهرباء كامل، حريق أو دخان):\n'
            '   severity="needs_provider", needs_clarification=false, direct_solution=null.\n'
            '   summary: أخبره أنها حالة طارئة وتحتاج فنياً فوراً، وستقترح له أفضل الفنيين.\n\n'

            '3) إذا طلب المستخدم صراحةً فنياً/مختصاً/محترفاً/مزود خدمة (حتى لو كانت '
            'المشكلة بسيطة وقابلة للحل ذاتياً):\n'
            '   severity="needs_provider", needs_clarification=false, direct_solution=null.\n'
            '   summary: أخبره أنك فهمت وستقترح له أفضل الفنيين، بدون شرح حل DIY.\n\n'

            '4) إذا كان بإمكانك تحديد التخصص لكن المستخدم لم يوضّح ما هو العطل بالتحديد '
            '(مثال: "عندي مشكلة بالباب" أو "في مشكلة بالجارور" بدون وصف ما يحدث بالضبط):\n'
            '   service_category=<التخصص المُحدَّد>, needs_clarification=true, '
            'severity="needs_provider", direct_solution=null.\n'
            '   summary: اشكره، واسأله بالتحديد ما الذي يحدث (مثال: هل هو عالق أم مكسور '
            'أم يصدر صوتاً؟ متى بدأت المشكلة؟) — لا تذكر فنيين هنا.\n\n'

            '5) إذا كان العطل واضحاً ويمكن للمستخدم إصلاحه بنفسه بخطوات بسيطة وآمنة:\n'
            '   severity="simple", needs_clarification=false, '
            'direct_solution=<خطوات DIY واضحة ومرقّمة>.\n'
            '   summary: أخبره أن الحل بسيط ويمكنه تجربته بنفسه أولاً.\n\n'

            '6) غير ذلك (العطل واضح لكنه يحتاج فنياً متخصصاً):\n'
            '   severity="needs_provider", needs_clarification=false, direct_solution=null.\n'
            '   summary: أخبره أنك فهمت وستقترح له أفضل الفنيين.\n\n'

            'أجب بـ JSON فقط بدون markdown أو ```، يحتوي على هذه المفاتيح بالضبط:\n'
            '  service_category: إحدى القيم [plumbing, electrical, painting, carpentry] أو ""\n'
            '  severity: "simple" أو "needs_provider"\n'
            '  needs_clarification: true أو false، حسب القاعدة المطبَّقة أعلاه\n'
            '  summary: رسالة ودية للمستخدم حسب القاعدة المطبَّقة\n'
            '  direct_solution: حل DIY مفصل إذا severity="simple"، وإلا null\n'
            '  confidence: رقم بين 0.0 و 1.0\n\n'
            f'رسالة المستخدم: {text}'
        )
        import json, time, logging
        log = logging.getLogger(__name__)
        last_exc = None
        for attempt in range(3):
            try:
                from google import genai
                response = self.client.models.generate_content(
                    model=self.MODEL,
                    contents=prompt,
                )
                raw = response.text.strip().strip('```json').strip('```').strip()
                data = json.loads(raw)
                data.setdefault('needs_clarification', False)
                return ProblemAnalysis(**data)
            except Exception as exc:
                last_exc = exc
                # Retry on transient server-side errors (503 overload); give up
                # immediately on quota exhaustion (429) or bad request (4xx).
                err_str = str(exc)
                if '503' in err_str or 'UNAVAILABLE' in err_str:
                    if attempt < 2:
                        time.sleep(2 ** attempt)
                        continue
                break
        log.warning('GeminiAIProvider failed after retries, falling back to rule-based: %s', last_exc)
        return RuleBasedAIProvider().analyze_text(text, lang=lang)

    def _gemini_json_analysis(self, parts: list, lang: str) -> ProblemAnalysis:
        """Shared helper: send multimodal parts to Gemini, parse JSON response."""
        import json

        cats = ', '.join(_CATEGORY_KEYWORDS.keys())
        lang_instruction = 'Respond in English.' if lang == 'en' else 'أجب باللغة العربية.'
        json_prompt = (
            f'You are a smart home maintenance assistant for the Handcom app. '
            f'Analyze the home maintenance problem. {lang_instruction} '
            f'Reply with JSON only, no markdown:\n'
            f'  service_category: one of [{cats}]\n'
            '  severity: "simple" or "needs_provider"\n'
            '  needs_clarification: false unless the content is completely ambiguous\n'
            '  summary: a friendly message to the user\n'
            '  direct_solution: step-by-step DIY fix if severity=simple, otherwise null\n'
            '  confidence: a number between 0.0 and 1.0'
        )
        response = self.client.models.generate_content(
            model=self.MODEL,
            contents=[*parts, json_prompt],
        )
        raw = response.text.strip().strip('```json').strip('```').strip()
        data = json.loads(raw)
        data.setdefault('needs_clarification', False)
        return ProblemAnalysis(**data)

    def analyze_image_file(self, image_file, lang: str = 'ar') -> ProblemAnalysis:
        """Analyze an uploaded image using Gemini Vision."""
        try:
            import mimetypes
            from google.genai import types

            image_bytes = image_file.read()
            image_file.seek(0)

            name = getattr(image_file, 'name', 'image.jpg')
            mime_type, _ = mimetypes.guess_type(name)
            mime_type = mime_type or 'image/jpeg'

            return self._gemini_json_analysis(
                [types.Part.from_bytes(data=image_bytes, mime_type=mime_type)],
                lang,
            )
        except Exception:
            return RuleBasedAIProvider().analyze_text('صورة لمشكلة في المنزل', lang=lang)

    def analyze_voice_file(self, voice_file, lang: str = 'ar') -> ProblemAnalysis:
        """Transcribe and analyze a voice message using Gemini."""
        try:
            import mimetypes
            from google.genai import types

            audio_bytes = voice_file.read()
            voice_file.seek(0)

            name = getattr(voice_file, 'name', 'audio.m4a')
            mime_type, _ = mimetypes.guess_type(name)
            mime_type = mime_type or 'audio/mp4'

            return self._gemini_json_analysis(
                [types.Part.from_bytes(data=audio_bytes, mime_type=mime_type)],
                lang,
            )
        except Exception:
            return RuleBasedAIProvider().analyze_text('رسالة صوتية', lang=lang)


def get_ai_provider() -> AIProvider:
    from django.conf import settings
    if getattr(settings, 'AI_PROVIDER', 'rule_based') == 'gemini':
        try:
            return GeminiAIProvider()
        except Exception:
            pass
    return RuleBasedAIProvider()


# ── Provider Recommender ──────────────────────────────────────────────────────

def _haversine_km(lat1, lon1, lat2, lon2):
    """Great-circle distance in km between two (lat, lon) points."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
         * math.sin(dlon / 2) ** 2)
    return R * 2 * math.asin(math.sqrt(a))


class ProviderRecommender:
    def recommend(self, category: str, user_location=None,
                  user_lat=None, user_lng=None, limit: int = 5) -> list:
        """Recommend providers ranked by: service type (DB filter) → location → rating."""
        from django.db.models import Avg, Count, Q
        from apps.accounts.models import ServiceProvider

        candidates = (
            ServiceProvider.objects
            .filter(service_categories__icontains=f'"{category}"', is_email_verified=True)
            .exclude(availability_status='offline')
            .annotate(
                cat_avg_rating=Avg(
                    'received_ratings__rating_value',
                    filter=Q(received_ratings__service_category=category),
                ),
                cat_rating_count=Count(
                    'received_ratings__rating_id',
                    filter=Q(received_ratings__service_category=category),
                ),
                overall_avg_rating=Avg('received_ratings__rating_value'),
                overall_rating_count=Count('received_ratings__rating_id'),
            )
        )

        has_location = user_lat is not None and user_lng is not None

        results = []
        for sp in candidates:
            # Prefer the provider's track record in this category; fall back to
            # their overall rating if they have no ratings for it yet.
            if sp.cat_rating_count:
                avg, total = sp.cat_avg_rating or 0.0, sp.cat_rating_count
            else:
                avg, total = sp.overall_avg_rating or 0.0, sp.overall_rating_count

            if has_location and sp.latitude is not None and sp.longitude is not None:
                distance_km = _haversine_km(user_lat, user_lng, sp.latitude, sp.longitude)
            else:
                distance_km = None
            results.append({
                'service_provider_id': sp.service_provider_id,
                'full_name': sp.full_name,
                'phone': sp.phone,
                'experience_years': sp.experience_years,
                'availability_status': sp.availability_status,
                'service_categories': sp.service_categories,
                'average_rating': round(avg, 2) if total else None,
                'total_ratings': total,
                'distance_km': round(distance_km, 1) if distance_km is not None else None,
                '_sort_distance': distance_km if distance_km is not None else float('inf'),
                '_sort_rating': avg,
            })

        # Service type is already guaranteed by the DB filter above (tier 1).
        # Tier 2: closer providers first (those without coordinates sort last).
        # Tier 3: higher-rated providers first.
        results.sort(key=lambda r: (r['_sort_distance'], -r['_sort_rating']))
        for r in results:
            del r['_sort_distance']
            del r['_sort_rating']
        return results[:limit]
