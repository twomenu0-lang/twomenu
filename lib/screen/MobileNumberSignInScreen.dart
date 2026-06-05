import 'dart:async';
import 'dart:convert';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../AppLocalizations.dart';
import '/../main.dart';
import '/../network/rest_apis.dart';
import '/../utils/AppBarWidget.dart';
import '/../screen/SignUpScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Constants.dart';
import '/../utils/AppImages.dart';
import 'package:nb_utils/nb_utils.dart';
import 'DashBoardScreen.dart';

class MobileNumberSignInScreen extends StatefulWidget {
  MobileNumberSignInScreen({Key? key, this.title}) : super(key: key);
  final String? title;

  @override
  _MobileNumberSignInScreenState createState() =>
      _MobileNumberSignInScreenState();
}

class _MobileNumberSignInScreenState extends State<MobileNumberSignInScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _verificationId;
  late String phoneNo;
  String code = "+20";
  String? smsOTP;
  String? data;
  int? _forceResendingToken;
  bool _isOtpDialogOpen = false; // ← منع فتح الـ Dialog مرتين
  var passwordCont = TextEditingController();

  String cleanPhoneNumber(String input, String dialCode) {
    String cleaned = input.trim();
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return dialCode + cleaned;
  }

  void verifyPhoneNumber({bool isResend = false}) async {
    appStore.setLoading(true);

    Timer? loadingTimeout = Timer(const Duration(seconds: 30), () {
      if (mounted && appStore.isLoading) {
        appStore.setLoading(false);
        toast('انتهت المهلة، تحقق من رقم الهاتف واتصالك بالإنترنت');
      }
    });

    PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) async {
      loadingTimeout.cancel();
      await _auth
          .signInWithCredential(phoneAuthCredential)
          .then((result) async {
        var request = {"username": this.data, "password": this.data};
        signInApi(request);
      }).catchError((e) {
        toast(e.toString());
        appStore.setLoading(false);
      });
    };

    PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      loadingTimeout.cancel();
      appStore.setLoading(false);
      switch (authException.code) {
        case 'invalid-phone-number':
          toast('رقم الهاتف غير صحيح');
          break;
        case 'too-many-requests':
          toast('تم تجاوز الحد المسموح، حاول لاحقاً');
          break;
        case 'missing-client-identifier':
        case 'app-not-authorized':
          toast('خطأ في إعداد التطبيق');
          break;
        case 'quota-exceeded':
          toast('تم استنفاد الحصة اليومية لـ SMS');
          break;
        default:
          toast('خطأ: ${authException.code}');
      }
    };

    PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      loadingTimeout.cancel();
      appStore.setLoading(false);
      _verificationId = verificationId;
      _forceResendingToken = forceResendingToken;
      toast('تم إرسال كود التحقق');
      if (!isResend && !_isOtpDialogOpen) {
        // ← تأخير بسيط للتأكد من إغلاق reCAPTCHA أولاً
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _isOtpDialogOpen = true;
          smsOTPDialog(context);
        }
      }
    };

    PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      _verificationId = verificationId;
    };

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: this.phoneNo,
        timeout: const Duration(seconds: 120),
        forceResendingToken: isResend ? _forceResendingToken : null,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
    } catch (e) {
      loadingTimeout.cancel();
      appStore.setLoading(false);
      toast('خطأ: $e');
    }
  }

  void signInWithPhoneNumber() async {
    appStore.setLoading(true);
    AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: smsOTP.validate());

    await _auth.signInWithCredential(credential).then((result) async {
      var request = {"username": this.data, "password": this.data};
      signInApi(request);
    }).catchError((e) {
      toast("كود التحقق خاطئ أو منتهي");
      appStore.setLoading(false);
    });
  }

  void signInApi(req) async {
    await login(req).then((res) async {
      if (!mounted) return;
      await setValue(USER_ID, res['user_id']);
      await setValue(FIRST_NAME, res['first_name']);
      await setValue(LAST_NAME, res['last_name']);
      await setValue(USER_EMAIL, res['user_email']);
      await setValue(USERNAME, res['user_nicename']);
      await setValue(TOKEN, res['token']);
      await setValue(AVATAR, res['avatar']);
      if (res['profile_image'] != null) {
        await setValue(PROFILE_IMAGE, res['profile_image']);
      }
      await setValue(USER_DISPLAY_NAME, res['user_display_name']);
      await setValue(BILLING, jsonEncode(res['billing']));
      await setValue(SHIPPING, jsonEncode(res['shipping']));
      await setValue(IS_SOCIAL_LOGIN, true);
      await setValue(IS_LOGGED_IN, true);
      appStore.setLoading(false);
      DashBoardScreen().launch(context, isNewTask: true);
    }).catchError((error) {
      log("Error: " + error.toString());
      appStore.setLoading(false);
      finish(context);
      SignUpScreen(userName: this.data.toString()).launch(context);
    });
  }

  Future<void> smsOTPDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _OtpDialog(
        phoneNumber: passwordCont.text,
        countryCode: code,
        onCompleted: (pin) {
          this.smsOTP = pin;
        },
        onConfirm: () {
          if (smsOTP != null && smsOTP!.length == 6) {
            hideKeyboard(context);
            Navigator.pop(context);
            _isOtpDialogOpen = false;
            toast("جاري التحقق...");
            signInWithPhoneNumber();
          } else {
            toast("أدخل الكود كاملاً (6 أرقام)");
          }
        },
        onResend: () {
          verifyPhoneNumber(isResend: true);
        },
      ),
    ).then((_) {
      _isOtpDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: mTop(context, "", showBack: true) as PreferredSizeWidget?,
        resizeToAvoidBottomInset: false,
        body: BodyCornerWidget(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Image.asset(
                    ic_mobileVerify,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        SizedBox(height: 150),
                  ),
                  24.height,
                  Container(
                    decoration: boxDecorationWithRoundedCorners(
                      backgroundColor: Theme.of(context).cardTheme.color!,
                      borderRadius: radius(8),
                      border: Border.all(
                        color: Theme.of(context).textTheme.titleMedium!.color!,
                      ),
                    ),
                    padding: EdgeInsets.only(left: 8),
                    child: Row(
                      children: <Widget>[
                        CountryCodePicker(
                          initialSelection: 'EG',
                          onChanged: (value) {
                            this.code = value.dialCode.toString();
                          },
                          backgroundColor: Colors.transparent,
                          showFlag: true,
                          padding: EdgeInsets.all(4),
                          dialogTextStyle: secondaryTextStyle(),
                          searchStyle: secondaryTextStyle(),
                          searchDecoration: InputDecoration(
                              labelStyle: secondaryTextStyle()),
                          dialogBackgroundColor:
                          Theme.of(context).cardTheme.color,
                          boxDecoration: BoxDecoration(
                            borderRadius: radius(4),
                            color: Theme.of(context).cardTheme.color!,
                          ),
                          textStyle: primaryTextStyle(),
                        ),
                        Container(
                          height: 30.0,
                          width: 1.0,
                          color: primaryColor,
                          margin: EdgeInsets.only(left: 10.0, right: 10.0),
                        ),
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            style: secondaryTextStyle(size: 18),
                            controller: passwordCont,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              counterText: "",
                              contentPadding:
                              EdgeInsets.fromLTRB(16, 0, 16, 0),
                              hintText: appLocalization
                                  .translate('lbl_enter_mobile_number'),
                              hintStyle: secondaryTextStyle(size: 18),
                              border: InputBorder.none,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  24.height,
                  AppButton(
                    width: context.width(),
                    text: appLocalization.translate('lbl_verify_now'),
                    onTap: () {
                      if (passwordCont.text.isEmpty) {
                        toast("يرجى إدخال رقم الهاتف");
                        return;
                      }
                      hideKeyboard(context);
                      this.phoneNo = cleanPhoneNumber(
                          passwordCont.text.toString(), this.code);
                      String cleaned = passwordCont.text.trim();
                      if (cleaned.startsWith('0')) {
                        cleaned = cleaned.substring(1);
                      }
                      this.data = cleaned;
                      verifyPhoneNumber();
                    },
                    textStyle: primaryTextStyle(color: white),
                    color: primaryColor,
                  ),
                ],
              ).center().paddingAll(16),
              Observer(
                builder: (context) => mProgress().visible(appStore.isLoading),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget مستقل لـ Dialog التحقق ───────────────────────────────────────────
class _OtpDialog extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final Function(String) onCompleted;
  final VoidCallback onConfirm;
  final VoidCallback onResend;

  const _OtpDialog({
    required this.phoneNumber,
    required this.countryCode,
    required this.onCompleted,
    required this.onConfirm,
    required this.onResend,
  });

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final List<TextEditingController> _controllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _fullOtp => _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _clearAll() {
    for (var c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 42,
      height: 52,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
          }
        },
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: boldTextStyle(size: 22),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: InputDecoration(
            counterText: "",
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: primaryColor!.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor!, width: 2),
            ),
            filled: true,
            fillColor: _controllers[index].text.isNotEmpty
                ? primaryColor!.withOpacity(0.08)
                : Colors.transparent,
          ),
          onChanged: (val) {
            setState(() {});
            if (val.isNotEmpty) {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                hideKeyboard(context);
              }
            } else {
              if (index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            }
            final otp = _fullOtp;
            if (otp.length == 6) {
              widget.onCompleted(otp);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayPhone = '${widget.countryCode} ${widget.phoneNumber}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أدخل رمز SMS',
                style: boldTextStyle(
                    size: 20,
                    color: Theme.of(context).textTheme.titleMedium!.color),
                textAlign: TextAlign.center,
              ),
              12.height,
              Text(
                'تم إرسال رمز التحقق إلى رقم هاتفك',
                style: secondaryTextStyle(size: 13),
                textAlign: TextAlign.center,
              ),
              6.height,
              Text(
                displayPhone,
                style: boldTextStyle(size: 14, color: primaryColor),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
              ),
              24.height,
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, _buildOtpBox),
                ),
              ),
              12.height,
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _clearAll,
                  child: Text('مسح',
                      style: secondaryTextStyle(
                          color: primaryColor, size: 12)),
                ),
              ),
              8.height,
              _canResend
                  ? TextButton(
                onPressed: () {
                  widget.onResend();
                  _startTimer();
                },
                child: Text(
                  'إعادة إرسال الرمز',
                  style: primaryTextStyle(color: primaryColor),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('إعادة إرسال الرمز خلال  ',
                      style: secondaryTextStyle(size: 13)),
                  Text(
                    _timerText,
                    style:
                    boldTextStyle(size: 13, color: primaryColor),
                  ),
                ],
              ),
              20.height,
              AppButton(
                width: context.width(),
                text: AppLocalizations.of(context)!.translate('lbl_done'),
                onTap: () {
                  final otp = _fullOtp;
                  if (otp.length == 6) {
                    widget.onCompleted(otp);
                    widget.onConfirm();
                  } else {
                    toast("أدخل الكود كاملاً (6 أرقام)");
                  }
                },
                textStyle: primaryTextStyle(color: white),
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}