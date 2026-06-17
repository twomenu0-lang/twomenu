// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'AppStore.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$AppStore on AppStoreBase, Store {
  late final _$isLoadingAtom =
      Atom(name: 'AppStoreBase.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$isLoggedInAtom =
      Atom(name: 'AppStoreBase.isLoggedIn', context: context);

  @override
  bool get isLoggedIn {
    _$isLoggedInAtom.reportRead();
    return super.isLoggedIn;
  }

  @override
  set isLoggedIn(bool value) {
    _$isLoggedInAtom.reportWrite(value, super.isLoggedIn, () {
      super.isLoggedIn = value;
    });
  }

  late final _$isNetworkAvailableAtom =
      Atom(name: 'AppStoreBase.isNetworkAvailable', context: context);

  @override
  bool get isNetworkAvailable {
    _$isNetworkAvailableAtom.reportRead();
    return super.isNetworkAvailable;
  }

  @override
  set isNetworkAvailable(bool value) {
    _$isNetworkAvailableAtom.reportWrite(value, super.isNetworkAvailable, () {
      super.isNetworkAvailable = value;
    });
  }

  late final _$isGuestUserLoggedInAtom =
      Atom(name: 'AppStoreBase.isGuestUserLoggedIn', context: context);

  @override
  bool get isGuestUserLoggedIn {
    _$isGuestUserLoggedInAtom.reportRead();
    return super.isGuestUserLoggedIn;
  }

  @override
  set isGuestUserLoggedIn(bool value) {
    _$isGuestUserLoggedInAtom.reportWrite(value, super.isGuestUserLoggedIn, () {
      super.isGuestUserLoggedIn = value;
    });
  }

  late final _$isDarkModeOnAtom =
      Atom(name: 'AppStoreBase.isDarkModeOn', context: context);

  @override
  bool get isDarkModeOn {
    _$isDarkModeOnAtom.reportRead();
    return super.isDarkModeOn;
  }

  @override
  set isDarkModeOn(bool value) {
    _$isDarkModeOnAtom.reportWrite(value, super.isDarkModeOn, () {
      super.isDarkModeOn = value;
    });
  }

  late final _$countAtom = Atom(name: 'AppStoreBase.count', context: context);

  @override
  int? get count {
    _$countAtom.reportRead();
    return super.count;
  }

  @override
  set count(int? value) {
    _$countAtom.reportWrite(value, super.count, () {
      super.count = value;
    });
  }

  late final _$mIsUserExistInReviewAtom =
      Atom(name: 'AppStoreBase.mIsUserExistInReview', context: context);

  @override
  bool get mIsUserExistInReview {
    _$mIsUserExistInReviewAtom.reportRead();
    return super.mIsUserExistInReview;
  }

  @override
  set mIsUserExistInReview(bool value) {
    _$mIsUserExistInReviewAtom.reportWrite(value, super.mIsUserExistInReview,
        () {
      super.mIsUserExistInReview = value;
    });
  }

  late final _$isNotificationOnAtom =
      Atom(name: 'AppStoreBase.isNotificationOn', context: context);

  @override
  bool get isNotificationOn {
    _$isNotificationOnAtom.reportRead();
    return super.isNotificationOn;
  }

  @override
  set isNotificationOn(bool value) {
    _$isNotificationOnAtom.reportWrite(value, super.isNotificationOn, () {
      super.isNotificationOn = value;
    });
  }

  late final _$isDarkModeAtom =
      Atom(name: 'AppStoreBase.isDarkMode', context: context);

  @override
  bool? get isDarkMode {
    _$isDarkModeAtom.reportRead();
    return super.isDarkMode;
  }

  @override
  set isDarkMode(bool? value) {
    _$isDarkModeAtom.reportWrite(value, super.isDarkMode, () {
      super.isDarkMode = value;
    });
  }

  late final _$unreadNotificationCountAtom =
      Atom(name: 'AppStoreBase.unreadNotificationCount', context: context);

  @override
  int get unreadNotificationCount {
    _$unreadNotificationCountAtom.reportRead();
    return super.unreadNotificationCount;
  }

  @override
  set unreadNotificationCount(int value) {
    _$unreadNotificationCountAtom
        .reportWrite(value, super.unreadNotificationCount, () {
      super.unreadNotificationCount = value;
    });
  }

  late final _$selectedLanguageCodeAtom =
      Atom(name: 'AppStoreBase.selectedLanguageCode', context: context);

  @override
  String get selectedLanguageCode {
    _$selectedLanguageCodeAtom.reportRead();
    return super.selectedLanguageCode;
  }

  @override
  set selectedLanguageCode(String value) {
    _$selectedLanguageCodeAtom.reportWrite(value, super.selectedLanguageCode,
        () {
      super.selectedLanguageCode = value;
    });
  }

  late final _$indexAtom = Atom(name: 'AppStoreBase.index', context: context);

  @override
  int get index {
    _$indexAtom.reportRead();
    return super.index;
  }

  @override
  set index(int value) {
    _$indexAtom.reportWrite(value, super.index, () {
      super.index = value;
    });
  }

  late final _$dashboardScreeListAtom =
      Atom(name: 'AppStoreBase.dashboardScreeList', context: context);

  @override
  List<Widget> get dashboardScreeList {
    _$dashboardScreeListAtom.reportRead();
    return super.dashboardScreeList;
  }

  @override
  set dashboardScreeList(List<Widget> value) {
    _$dashboardScreeListAtom.reportWrite(value, super.dashboardScreeList, () {
      super.dashboardScreeList = value;
    });
  }

  late final _$toggleDarkModeAsyncAction =
      AsyncAction('AppStoreBase.toggleDarkMode', context: context);

  @override
  Future<void> toggleDarkMode({bool? value}) {
    return _$toggleDarkModeAsyncAction
        .run(() => super.toggleDarkMode(value: value));
  }

  late final _$setDarkModeAsyncAction =
      AsyncAction('AppStoreBase.setDarkMode', context: context);

  @override
  Future<void> setDarkMode({bool? aIsDarkMode}) {
    return _$setDarkModeAsyncAction
        .run(() => super.setDarkMode(aIsDarkMode: aIsDarkMode));
  }

  late final _$setLanguageAsyncAction =
      AsyncAction('AppStoreBase.setLanguage', context: context);

  @override
  Future<void> setLanguage(String aSelectedLanguageCode) {
    return _$setLanguageAsyncAction
        .run(() => super.setLanguage(aSelectedLanguageCode));
  }

  late final _$AppStoreBaseActionController =
      ActionController(name: 'AppStoreBase', context: context);

  @override
  void setLoading(bool aIsLoading) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setLoading');
    try {
      return super.setLoading(aIsLoading);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setConnectionState(ConnectivityResult val) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setConnectionState');
    try {
      return super.setConnectionState(val);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBottomNavigationIndex(int val) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setBottomNavigationIndex');
    try {
      return super.setBottomNavigationIndex(val);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLoggedIn(bool val) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setLoggedIn');
    try {
      return super.setLoggedIn(val);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setGuestUserLoggedIn(bool val) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setGuestUserLoggedIn');
    try {
      return super.setGuestUserLoggedIn(val);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void increment() {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.increment');
    try {
      return super.increment();
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void decrement({int? qty}) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.decrement');
    try {
      return super.decrement(qty: qty);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setCount(int? aCount) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setCount');
    try {
      return super.setCount(aCount);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setUnreadNotificationCount(int val) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setUnreadNotificationCount');
    try {
      return super.setUnreadNotificationCount(val);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setNotification(bool val) {
    final _$actionInfo = _$AppStoreBaseActionController.startAction(
        name: 'AppStoreBase.setNotification');
    try {
      return super.setNotification(val);
    } finally {
      _$AppStoreBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isLoggedIn: ${isLoggedIn},
isNetworkAvailable: ${isNetworkAvailable},
isGuestUserLoggedIn: ${isGuestUserLoggedIn},
isDarkModeOn: ${isDarkModeOn},
count: ${count},
mIsUserExistInReview: ${mIsUserExistInReview},
isNotificationOn: ${isNotificationOn},
isDarkMode: ${isDarkMode},
unreadNotificationCount: ${unreadNotificationCount},
selectedLanguageCode: ${selectedLanguageCode},
index: ${index},
dashboardScreeList: ${dashboardScreeList}
    ''';
  }
}
