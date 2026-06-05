import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultCategories.dart';
import 'package:budget/database/generatePreviewData.dart';

//Initialize default values in database
Future<bool> initializeDefaultDatabase() async {
  // A previous testing build accidentally enabled preview data for every user.
  // Clean it up on update so testers return to an empty real database.
  if (appStateSettings["previewDemo"] == true) {
    await deletePreviewData();
    return true;
  }

  //Initialize default categories, but not after a backup load
  if (isDatabaseImportedOnThisSession != true &&
      (await database.getAllCategories()).length <= 0) {
    await createDefaultCategories();
  }

  if ((await database.getAllWallets()).length <= 0) {
    await database.createOrUpdateWallet(
      defaultWallet(),
      customDateTimeModified: DateTime(0),
    );
  }

  return true;
}

Future<bool> createDefaultCategories() async {
  print("Creating default categories");
  for (TransactionCategory category in defaultCategories()) {
    try {
      await database.getCategory(category.categoryPk).$2;
    } catch (e) {
      print(
          e.toString() + " default category does not already exist, creating");
      await database.createOrUpdateCategory(category,
          customDateTimeModified: DateTime(0));
    }
  }
  return true;
}

TransactionWallet defaultWallet() {
  return TransactionWallet(
    walletPk: "0",
    name: "default-account-name".tr(),
    dateCreated: DateTime.now(),
    order: 0,
    currency: getDevicesDefaultCurrencyCode(),
    dateTimeModified: null,
    decimals: 2,
    homePageWidgetDisplay: defaultWalletHomePageWidgetDisplay,
  );
}
