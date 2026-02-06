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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        children: [
          // --- Header Section ---
          const Text(
            "Ready to scale your institution?",
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          const Text(
            "Choose a plan that fits your needs. Get 2 months free with a yearly subscription.",
            style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 40),

          _buildPeriodToggle(),

          const SizedBox(height: 60),

          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCard(
                  title: "Starter",
                  price: "0",
                  description: "Essential features for small teams and test projects.",
                  features: ["Up to 50 Users", "Basic Analytics", "Community Support", "1GB Storage"],
                  buttonText: "Current Plan",
                  isPopular: false,
                  isCurrent: true,
                ),
                const SizedBox(width: 24),
                _buildCard(
                  title: "Professional",
                  price: isYearly ? "80" : "99",
                  period: isYearly ? "/mo (billed yearly)" : "/month",
                  description: "Advanced features for growing schools and institutes.",
                  features: [
                    "Unlimited Users",
                    "Advanced Analytics",
                    "Priority Email Support",
                    "100GB Storage",
                    "Custom Domain",
                    "API Access"
                  ],
                  buttonText: "Upgrade Now",
                  isPopular: true,
                  isCurrent: false,
                ),
                const SizedBox(width: 24),
                _buildCard(
                  title: "Enterprise",
                  price: "Custom",
                  description: "Full-scale solution for large universities and enterprises.",
                  features: [
                    "On-premise Hosting",
                    "Custom Integrations",
                    "Dedicated Manager",
                    "SLA Support",
                    "Unlimited Storage",
                    "White-labeling"
                  ],
                  buttonText: "Contact Sales",
                  isPopular: false,
                  isCurrent: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Monthly", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: !isYearly ? const Color(0xFF0F172A) : Colors.black26,
          )
        ),
        const SizedBox(width: 16),
        
        GestureDetector(
          onTap: () => setState(() => isYearly = !isYearly),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 60,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(

              color: isYearly ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,

              alignment: isYearly ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white, 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ]
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        Text(
          "Yearly", 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: isYearly ? const Color(0xFF0F172A) : Colors.black26,
          )
        ),
        const SizedBox(width: 12),
        
        // Badge الخصم
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            "Save 20%", 
            style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold)
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required String price,
    String period = "",
    required String description,
    required List<String> features,
    required String buttonText,
    required bool isPopular,
    required bool isCurrent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPopular ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isPopular ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPopular ? const Color(0xFF2563EB).withOpacity(0.08) : Colors.black.withOpacity(0.03),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                child: const Text("MOST POPULAR", style: TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price != "Custom") const Padding(
                  padding: EdgeInsets.only(bottom: 8, right: 2),
                  child: Text("\$", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ),
                Text(price, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                if (period.isNotEmpty) Padding(
                  padding: const EdgeInsets.only(bottom: 10, left: 4),
                  child: Text(period, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description, style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                children: features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(feature, style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? const Color(0xFF2563EB) : Colors.white,
                  foregroundColor: isPopular ? Colors.white : const Color(0xFF2563EB),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  side: BorderSide(color: isPopular ? Colors.transparent : const Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}