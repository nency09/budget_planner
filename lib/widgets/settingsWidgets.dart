import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/outlinedButtonStacked.dart';
import 'package:budget/widgets/selectAmount.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NumberPadFormatSettingPopup extends StatefulWidget {
  const NumberPadFormatSettingPopup({super.key});

  @override
  State<NumberPadFormatSettingPopup> createState() =>
      _NumberPadFormatSettingPopupState();
}

class _NumberPadFormatSettingPopupState
    extends State<NumberPadFormatSettingPopup> {
  @override
  Widget build(BuildContext context) {
    return PopupFramework(
      title: "number-pad-format".tr(),
      child: Column(
        children: [
          ExtraZerosButtonSetting(
            enableBorderRadius: true,
            onChange: () {
              setState(() {});
            },
          ),
          NumberPadHapticFeedbackSetting(
            enableBorderRadius: true,
          ),
          HorizontalBreak(),
          SizedBox(height: 10),
          NumberPadFormatPicker(),
        ],
      ),
    );
  }
}

class FirstDayOfWeekSetting extends StatelessWidget {
  const FirstDayOfWeekSetting({required this.updateHomePage, super.key});
  final bool updateHomePage;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      title: "first-weekday".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.calendar_month_outlined
          : Icons.calendar_month_rounded,
      initial: appStateSettings["firstDayOfWeek"].toString(),
      items: ["-1", "0", "1"],
      onChanged: (value) async {
        int intValue = int.tryParse(value) ?? -1;
        await updateSettings(
          "firstDayOfWeek",
          intValue,
          updateGlobalState: false,
          pagesNeedingRefresh: updateHomePage ? [0] : [],
        );
      },
      getLabel: (item) {
        List<String> weekDayNames = getWeekdayNames();
        if (item == "-1") return "default".tr();
        if (item == "0") return weekDayNames[0];
        if (item == "1") return weekDayNames[1];
      },
    );
  }
}

class NumberPadFormatPicker extends StatefulWidget {
  const NumberPadFormatPicker({super.key});

  @override
  State<NumberPadFormatPicker> createState() => _NumberPadFormatPickerState();
}

class _NumberPadFormatPickerState extends State<NumberPadFormatPicker> {
  NumberPadFormat selectedNumberPadFormat = getNumberPadFormat();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: selectedNumberPadFormat == NumberPadFormat.format123
                    ? 1
                    : 0.5,
                child: OutlinedButtonStacked(
                  filled: selectedNumberPadFormat == NumberPadFormat.format123,
                  alignStart: true,
                  alignBeside: true,
                  text: null,
                  afterWidget: IgnorePointer(
                    child: NumberPadAmount(
                      extraWidgetAboveNumbers: null,
                      addToAmount: (_) {},
                      enableDecimal: true,
                      removeToAmount: () {},
                      removeAll: () {},
                      canChange: () => true,
                      enableCalculator: true,
                      padding: EdgeInsetsDirectional.zero,
                      setState: () {},
                      format: NumberPadFormat.format123,
                    ),
                  ),
                  padding: EdgeInsetsDirectional.only(
                      start: 20, end: 15, top: 10, bottom: 15),
                  iconData: null,
                  onTap: () {
                    setState(() {
                      selectedNumberPadFormat = NumberPadFormat.format123;
                    });
                    updateSettings(
                        "numberPadFormat", NumberPadFormat.format123.index,
                        updateGlobalState: false);
                  },
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: selectedNumberPadFormat == NumberPadFormat.format789
                    ? 1
                    : 0.5,
                child: OutlinedButtonStacked(
                  filled: selectedNumberPadFormat == NumberPadFormat.format789,
                  alignStart: true,
                  alignBeside: true,
                  text: null,
                  afterWidget: IgnorePointer(
                    child: NumberPadAmount(
                      extraWidgetAboveNumbers: null,
                      addToAmount: (_) {},
                      enableDecimal: true,
                      removeToAmount: () {},
                      removeAll: () {},
                      canChange: () => true,
                      enableCalculator: true,
                      padding: EdgeInsetsDirectional.zero,
                      setState: () {},
                      format: NumberPadFormat.format789,
                    ),
                  ),
                  padding: EdgeInsetsDirectional.only(
                      start: 20, end: 15, top: 10, bottom: 15),
                  iconData: null,
                  onTap: () {
                    setState(() {
                      selectedNumberPadFormat = NumberPadFormat.format789;
                    });
                    updateSettings(
                        "numberPadFormat", NumberPadFormat.format789.index,
                        updateGlobalState: false);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ExtraZerosButtonSetting extends StatelessWidget {
  const ExtraZerosButtonSetting(
      {this.onChange, this.enableBorderRadius = false, super.key});
  final bool enableBorderRadius;
  final VoidCallback? onChange;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerDropdown(
      enableBorderRadius: enableBorderRadius,
      title: "extra-zeros-button".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Symbols.counter_0_sharp
          : Symbols.counter_0_rounded,
      initial: appStateSettings["extraZerosButton"].toString(),
      items: ["", "00", "000"],
      onChanged: (value) async {
        await updateSettings(
          "extraZerosButton",
          value == "" ? null : value,
          updateGlobalState: false,
        );
        if (onChange != null) onChange!();
      },
      getLabel: (item) {
        if (item == "") return "none".tr().capitalizeFirst;
        return item;
      },
    );
  }
}

class NumberPadHapticFeedbackSetting extends StatelessWidget {
  const NumberPadHapticFeedbackSetting(
      {this.enableBorderRadius = false, super.key});
  final bool enableBorderRadius;
  @override
  Widget build(BuildContext context) {
    return SettingsContainerSwitch(
      enableBorderRadius: enableBorderRadius,
      title: "haptic-feedback".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.vibration_outlined
          : Symbols.vibration_rounded,
      initialValue: appStateSettings["numberPadHapticFeedback"] == true,
      onSwitched: (value) async {
        if (value == true) HapticFeedback.heavyImpact();
        await updateSettings(
          "numberPadHapticFeedback",
          value,
          updateGlobalState: false,
        );
      },
    );
  }
}

class HorizontalBreak extends StatelessWidget {
  const HorizontalBreak(
      {this.padding = const EdgeInsetsDirectional.symmetric(vertical: 10),
      super.key});
  final EdgeInsetsDirectional padding;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        height: 1,
        color: getColor(context, "dividerColor"),
      ),
    );
  }
}

List<String> getWeekdayNames() {
  List<String> localizedWeekdayNames = [];
  final String? locale = navigatorKey.currentContext?.locale.toString();
  
  for (int i = 0; i < 7; i++) {
    DateTime date = DateTime(2023, 1, 2 + i); // Start from Monday
    String weekdayName = DateFormat.EEEE(locale).format(date);
    localizedWeekdayNames.add(weekdayName);
  }
  
  return localizedWeekdayNames;
}