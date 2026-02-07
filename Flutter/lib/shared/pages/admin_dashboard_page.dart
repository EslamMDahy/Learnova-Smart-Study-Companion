// import 'package:flutter/material.dart';
// import 'package:learnova/features/admin/dashboard/widgets/NotificationsContent.dart';
// import 'widgets/sidebar.dart';
// import 'widgets/top_header.dart';
// import 'widgets/empty_org_state.dart';
// import 'widgets/user_management_content.dart';
// import 'widgets/join_requests_content.dart';
// import 'widgets/upgrade_plans_content.dart';
// import 'widgets/settings_content.dart';

// class AdminDashboardPage extends StatefulWidget {
//   const AdminDashboardPage({super.key});

//   @override
//   State<AdminDashboardPage> createState() => _AdminDashboardPageState();
// }

// class _AdminDashboardPageState extends State<AdminDashboardPage> {
//   bool hasOrganization = true;
//   int selectedIndex = 3;
  
//   bool isNotificationsView = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: Row(
//         children: [
//           SidebarWidget(
//             selectedIndex: selectedIndex,
//             onItemSelected: (index) {
//               if (hasOrganization) {
//                 setState(() {
//                   selectedIndex = index;
//                   isNotificationsView = false; // العودة للحالة الطبيعية عند تغيير القسم
//                 });
//               }
//             },
//           ),
//           Expanded(
//             child: Column(
//               children: [
//                 // ✅ التعديل هنا: تمرير حالة الإشعارات ودالة الرجوع للهيدر
//                 TopHeaderWidget(
//                   isNotificationsView: isNotificationsView,
//                   onBack: () {
//                     setState(() {
//                       isNotificationsView = false;
//                     });
//                   },
//                 ),
//                 Expanded(
//                   child: AnimatedSwitcher(
//                     duration: const Duration(milliseconds: 300),
//                     child: KeyedSubtree(
//                       key: ValueKey(isNotificationsView.toString() + selectedIndex.toString()),
//                       child: _buildMainBody(),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainBody() {
//     if (!hasOrganization) {
//       return EmptyOrgState(
//         onOrgCreated: () => setState(() => hasOrganization = true),
//       );
//     }

//     switch (selectedIndex) {
//       case 0: return const UserManagementContent();
//       case 1: return const JoinRequestsContent();
//       case 2: return const UpgradePlansContent();
//       case 3:
//         if (isNotificationsView) {
//           return const NotificationsContent(); 
//         }
//         return SettingsContent(
//           onShowNotifications: () => setState(() => isNotificationsView = true),
//         );
//       case 4: return _buildHelpPlaceholder();
//       default: return const UserManagementContent();
//     }
//   }

//   Widget _buildHelpPlaceholder() {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.help_outline_rounded, size: 64, color: Colors.black26),
//           SizedBox(height: 16),
//           Text("Help Center", 
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54)),
//         ],
//       ),
//     );
//   }
// }