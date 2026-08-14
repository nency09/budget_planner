import 'package:budget/struct/settings.dart';
import 'package:budget/services/smart_notifications_service.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:flutter/material.dart';

/// Smart Notifications Settings Widget
/// Allows users to control which high-value notifications they receive
class SmartNotificationsSettings extends StatelessWidget {
  const SmartNotificationsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainerSwitch(
          title: "Weekly Money Story",
          description: "Get a weekly summary of your spending",
          onSwitched: (value) async {
            await updateSettings("weeklyInsights", value,
                updateGlobalState: false);
            await SmartNotificationsService()
                .applySmartNotificationPreferences();
          },
          initialValue: appStateSettings["weeklyInsights"] ?? true,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.auto_stories_outlined
              : Icons.auto_stories_rounded,
        ),
        SettingsContainerSwitch(
          title: "Smart Savings Tips",
          description: "Get notified when we find ways to save money",
          onSwitched: (value) async {
            await updateSettings("savingsOpportunities", value,
                updateGlobalState: false);
          },
          initialValue: appStateSettings["savingsOpportunities"] ?? true,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.lightbulb_outlined
              : Icons.lightbulb_rounded,
        ),
        SettingsContainerSwitch(
          title: "Achievement Celebrations",
          description: "Celebrate when you reach goals and stay within budgets",
          onSwitched: (value) async {
            await updateSettings("goalReminders", value,
                updateGlobalState: false);
          },
          initialValue: appStateSettings["goalReminders"] ?? true,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.celebration_outlined
              : Icons.celebration_rounded,
        ),
        SettingsContainerSwitch(
          title: "Budget Alerts",
          description: "Get gentle warnings when approaching budget limits",
          onSwitched: (value) async {
            await updateSettings("budgetAlerts", value,
                updateGlobalState: false);
          },
          initialValue: appStateSettings["budgetAlerts"] ?? true,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.warning_amber_outlined
              : Icons.warning_amber_rounded,
        ),
        SettingsContainerSwitch(
          title: "Transaction Insights",
          description: "Get help categorizing large transactions",
          onSwitched: (value) async {
            await updateSettings("transactionInsights", value,
                updateGlobalState: false);
          },
          initialValue: appStateSettings["transactionInsights"] ?? true,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.receipt_long_outlined
              : Icons.receipt_long_rounded,
        ),
        SettingsContainerSwitch(
          title: "Subscription Reminders",
          description: "Get reminded before subscriptions renew",
          onSwitched: (value) async {
            await updateSettings("subscriptionReminders", value,
                updateGlobalState: false);
            await SmartNotificationsService()
                .applySmartNotificationPreferences();
          },
          initialValue: appStateSettings["subscriptionReminders"] ?? true,
          icon: appStateSettings["outlinedIcons"]
              ? Icons.subscriptions_outlined
              : Icons.subscriptions_rounded,
        ),
        const SizedBox(height: 10),
        SettingsHeader(title: "Quiet Hours"),
        QuietHoursSettings(),
      ],
    );
  }
}

class QuietHoursSettings extends StatelessWidget {
  const QuietHoursSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SettingsContainer(
          title: "Quiet Hours Start",
          description: "No notifications after this time",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.bedtime_outlined
              : Icons.bedtime_rounded,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: appStateSettings["quietHoursStart"] ?? 22,
                minute: 0,
              ),
            );
            if (time != null) {
              await updateSettings("quietHoursStart", time.hour,
                  updateGlobalState: false);
              await SmartNotificationsService()
                  .applySmartNotificationPreferences();
            }
          },
          afterWidget: Text(
            _formatHour(appStateSettings["quietHoursStart"] ?? 22),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SettingsContainer(
          title: "Quiet Hours End",
          description: "Resume notifications after this time",
          icon: appStateSettings["outlinedIcons"]
              ? Icons.wb_sunny_outlined
              : Icons.wb_sunny_rounded,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: appStateSettings["quietHoursEnd"] ?? 8,
                minute: 0,
              ),
            );
            if (time != null) {
              await updateSettings("quietHoursEnd", time.hour,
                  updateGlobalState: false);
              await SmartNotificationsService()
                  .applySmartNotificationPreferences();
            }
          },
          afterWidget: Text(
            _formatHour(appStateSettings["quietHoursEnd"] ?? 8),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatHour(int hour) {
    if (hour == 0) return "12:00 AM";
    if (hour < 12) return "$hour:00 AM";
    if (hour == 12) return "12:00 PM";
    return "${hour - 12}:00 PM";
  }
}

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({required this.title, super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
