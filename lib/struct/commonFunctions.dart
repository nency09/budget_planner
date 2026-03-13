import 'package:flutter/services.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/pages/addTransactionPage.dart' show SelectText;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Provides haptic feedback when saving if enabled in settings
void savingHapticFeedback() {
  if (appStateSettings["savingHapticFeedback"] == true) {
    HapticFeedback.lightImpact();
  }
}

/// Shows a bottom sheet for entering a username
Future<String> enterNameBottomSheet(context, {bool updatePageWhenSet = true}) async {
  return await openBottomSheet(
    context,
    PopupFramework(
      title: "enter-name".tr(),
      child: SelectText(
        buttonLabel: "set-name".tr(),
        setSelectedText: (text) async {
          await updateSettings("username", text, updateGlobalState: updatePageWhenSet);
          return text;
        },
        nextWithInput: (text) {
          return text.trim().length > 0;
        },
        placeholder: "name".tr(),
        autoFocus: true,
        selectedText: appStateSettings["username"],
      ),
    ),
  );
}