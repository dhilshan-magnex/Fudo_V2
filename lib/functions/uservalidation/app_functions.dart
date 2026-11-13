class AppFunctions {
  AppFunctions._();

  // Screen_ID values used by User_Setup.
  static const String dataSyncScreen = 'DATASYNC';
  static const String billingScreen = 'BILLING';
  static const String posSettingsScreen = 'POSSETT';
  static const String categoryScreen = 'CAT';
  static const String menuItemScreen = 'MENUITM';
  static const String systemSettingsScreen = 'SYSSETT';
  static const String dashboardScreen = 'DASHBRD';
  static const String reportsScreen = 'REPO';
  static const String posMachineScreen = 'POSMAC';
  static const String posAccessScreen = 'POSACC';
  static const String discountScreen = 'DISCSCR';
  static const String taxMasterScreen = 'TAXMAST';
  static const String paymentScreen = 'PAY';
  static const String foreignCurrencyScreen = 'FXC';
  static const String creditCardScreen = 'CCRD';
  static const String kotSetupScreen = 'KOTSETUP';
  static const String dayEndScreen = 'DAYEND';
  static const String kdsSetupScreen = 'KDSSETUP';
  static const String excScreen = 'EXC';
  static const String cashOutScreen = 'CASHOUT';
  static const String changeWaiterScreen = 'CHNGW';
  static const String noPriceScreen = 'NOPRICE';
  static const String adjustPaymentScreen = 'ADJPAY';
  static const String cpayScreen = 'CPAY';
  static const String payoutScreen = 'PAYOUT';
  static const String dlScreen = 'DL';
  static const String takeawayScreen = 'TO';
  static const String saveScreen = 'SAVE';
  static const String openCheckScreen = 'OPCHK';
  static const String cancelScreen = 'CANCEL';
  static const String splitScreen = 'SPLIT';
  static const String mergeScreen = 'MERGE';
  static const String voidScreen = 'VOID';
  static const String discScreen = 'DISC';
  static const String complimentaryScreen = 'COMP';

  // Blank Function_ID denotes a screen-level permission.
  static const String screenAccess = '';

  // Existing function-specific permissions used by billing and data sync.
  static const String dataSync = 'SYNC';
  static const String billing = 'BILL';
}
