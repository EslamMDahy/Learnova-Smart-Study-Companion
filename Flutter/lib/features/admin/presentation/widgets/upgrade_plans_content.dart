import 'package:flutter/material.dart';

class UpgradePlansContent extends StatefulWidget {
  const UpgradePlansContent({super.key});

  @override
  State<UpgradePlansContent> createState() => _UpgradePlansContentState();
}

class _UpgradePlansContentState extends State<UpgradePlansContent> {
  bool isYearly = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isNarrow = c.maxWidth < 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Ready to scale your institution?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Choose a plan that fits your needs. Get 2 months free with a yearly subscription.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 22),

                  _PeriodToggle(
                    isYearly: isYearly,
                    onToggle: () => setState(() => isYearly = !isYearly),
                  ),

                  const SizedBox(height: 28),

                  if (isNarrow) ...[
                    _PlanCard(
                      title: "Starter",
                      price: "0",
                      period: isYearly ? "/yr" : "/mo",
                      description: "Essential features for small teams and test projects.",
                      features: const [
                        "Up to 50 Users",
                        "Basic Analytics",
                        "Community Support",
                        "1GB Storage",
                      ],
                      buttonText: "Current Plan",
                      isPopular: false,
                      isCurrent: true,
                      tone: _Tone.neutral,
                      onPressed: null,
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      title: "Professional",
                      price: isYearly ? "80" : "99",
                      period: isYearly ? "/mo (billed yearly)" : "/month",
                      description: "Advanced features for growing schools and institutes.",
                      features: const [
                        "Unlimited Users",
                        "Advanced Analytics",
                        "Priority Email Support",
                        "100GB Storage",
                        "Custom Domain",
                        "API Access",
                      ],
                      buttonText: "Upgrade Now",
                      isPopular: true,
                      isCurrent: false,
                      tone: _Tone.primary,
                      onPressed: () {},
                    ),
                    const SizedBox(height: 16),
                    _PlanCard(
                      title: "Enterprise",
                      price: "Custom",
                      period: "",
                      description: "Full-scale solution for large universities and enterprises.",
                      features: const [
                        "On-premise Hosting",
                        "Custom Integrations",
                        "Dedicated Manager",
                        "SLA Support",
                        "Unlimited Storage",
                        "White-labeling",
                      ],
                      buttonText: "Contact Sales",
                      isPopular: false,
                      isCurrent: false,
                      tone: _Tone.neutral,
                      onPressed: () {},
                    ),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PlanCard(
                            title: "Starter",
                            price: "0",
                            period: isYearly ? "/yr" : "/mo",
                            description: "Essential features for small teams and test projects.",
                            features: const [
                              "Up to 50 Users",
                              "Basic Analytics",
                              "Community Support",
                              "1GB Storage",
                            ],
                            buttonText: "Current Plan",
                            isPopular: false,
                            isCurrent: true,
                            tone: _Tone.neutral,
                            onPressed: null,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _PlanCard(
                            title: "Professional",
                            price: isYearly ? "80" : "99",
                            period: isYearly ? "/mo (billed yearly)" : "/month",
                            description: "Advanced features for growing schools and institutes.",
                            features: const [
                              "Unlimited Users",
                              "Advanced Analytics",
                              "Priority Email Support",
                              "100GB Storage",
                              "Custom Domain",
                              "API Access",
                            ],
                            buttonText: "Upgrade Now",
                            isPopular: true,
                            isCurrent: false,
                            tone: _Tone.primary,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: _PlanCard(
                            title: "Enterprise",
                            price: "Custom",
                            period: "",
                            description: "Full-scale solution for large universities and enterprises.",
                            features: const [
                              "On-premise Hosting",
                              "Custom Integrations",
                              "Dedicated Manager",
                              "SLA Support",
                              "Unlimited Storage",
                              "White-labeling",
                            ],
                            buttonText: "Contact Sales",
                            isPopular: false,
                            isCurrent: false,
                            tone: _Tone.neutral,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 10),
                        Text(
                          "Secure payments · Cancel anytime · Invoice available",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ---------------- Toggle ---------------- */

class _PeriodToggle extends StatelessWidget {
  final bool isYearly;
  final VoidCallback onToggle;

  const _PeriodToggle({required this.isYearly, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            text: "Monthly",
            selected: !isYearly,
            onTap: isYearly ? onToggle : null,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            text: "Yearly",
            selected: isYearly,
            onTap: !isYearly ? onToggle : null,
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              "Save 20%",
              style: TextStyle(
                color: Color(0xFF166534),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  const _ToggleChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

/* ---------------- Card ---------------- */

enum _Tone { primary, neutral }

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final String buttonText;
  final bool isPopular;
  final bool isCurrent;
  final _Tone tone;
  final VoidCallback? onPressed;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.isPopular,
    required this.isCurrent,
    required this.tone,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = tone == _Tone.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPrimary ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: isPrimary ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? const Color(0xFF2563EB).withOpacity(0.10)
                : const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                "MOST POPULAR",
                style: TextStyle(
                  color: Color(0xFF1E40AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (price != "Custom")
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, right: 2),
                  child: Text(
                    "\$",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (period.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 6),
                  child: Text(
                    period,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1.4),
          const SizedBox(height: 16),

          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isPrimary ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isPrimary ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrent ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary ? const Color(0xFF2563EB) : Colors.white,
                disabledBackgroundColor: const Color(0xFF93C5FD),
                foregroundColor: isPrimary ? Colors.white : const Color(0xFF2563EB),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: isPrimary ? Colors.transparent : const Color(0xFFE2E8F0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
