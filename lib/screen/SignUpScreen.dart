import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '/../main.dart';
import '/../network/rest_apis.dart';
import '/../screen/DashBoardScreen.dart';
import '/../utils/AppWidget.dart';
import '/../utils/Constants.dart';
import 'package:nb_utils/nb_utils.dart';

import '../AppLocalizations.dart';
import '../utils/AppBarWidget.dart';
import '../utils/Common.dart'; // ✅ مطلوب لاستخدام cleanInputText
import '../component/RewardWelcomeDialog.dart'; // ✅ الدايلوج الموحّد لهدية الترحيب

class SignUpScreen extends StatefulWidget {
  static String tag = '/SignUpScreen';
  final String? userName;

  const SignUpScreen({super.key, this.userName});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController usernameCont = TextEditingController();
  TextEditingController passwordCont = TextEditingController();
  TextEditingController confirmPasswordCont = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  signUpApi() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);

      var request = {
        'first_name': cleanInputText(fNameCont.text),
        'last_name': cleanInputText(lNameCont.text),
        'user_email': cleanInputText(emailCont.text),
        'user_type': null,
        'user_login': widget.userName ?? cleanInputText(usernameCont.text),
        'user_pass': widget.userName ?? passwordCont.text
      };

      log("Request$request");
      appStore.setLoading(true);

      createCustomer(request).then((res) async {
        if (!mounted) return;
        if (widget.userName != null) {
          if (widget.userName!.isNotEmpty) {
            var request = {
              "username": widget.userName,
              "password": widget.userName,
            };

            log("Request$request");
            signInApi(request);
          } else {
            toast(AppLocalizations.of(context)!.translate('lbl_register_success'));
            var loginReq = {
              "username": cleanInputText(usernameCont.text),
              "password": passwordCont.text,
            };
            log("Request$loginReq");
            signInApi(loginReq);
          }
        } else {
          toast(AppLocalizations.of(context)!.translate('lbl_register_success'));
          var loginReq = {
            "username": cleanInputText(usernameCont.text),
            "password": passwordCont.text,
          };
          log("Request$loginReq");
          signInApi(loginReq);
        }

        appStore.setLoading(false);
      }).catchError((error) {
        appStore.setLoading(false);
        toast(error.toString(), print: true);
      });
    }
  }

  void socialLogin(req) async {
    appStore.setLoading(true);

    await socialLoginApi(req).then((res) async {
      if (!mounted) return;
      await getCustomer(res['user_id']).then((response) async {
        if (!mounted) return;

        await setValue(IS_SOCIAL_LOGIN, true);
        await setValue(AVATAR, req['photoURL']);
        await setValue(USER_ID, res['user_id']);
        await setValue(FIRST_NAME, res['first_name']);
        await setValue(LAST_NAME, res['last_name']);
        await setValue(USER_EMAIL, res['user_email']);
        await setValue(USERNAME, res['user_nicename']);
        await setValue(TOKEN, res['token']);
        await setValue(USER_DISPLAY_NAME, res['user_display_name']);
        appStore.setLoggedIn(true);

        // ✅ v1.7.5-fix — نفس التعديل في مسار التسجيل/الدخول بـ Google/Apple
        // من شاشة SignUpScreen.
        await savePlayerIdToServer();

        // ✅ توحيد ظهور دايلوج هدية الترحيب: نعتمد على فلاج is_new_user
        // الراجع من الباك إند (mighty_get_customer_by_social) بدل أي تخمين
        // في الفرونت. الدايلوج يظهر فقط لو الحساب اتعمل دلوقتي فعلاً —
        // مش لأي تسجيل دخول عادي بجوجل/أبل لمستخدم موجود من قبل ليه
        // مكافآت تانية (ترقية مستوى مثلاً) مش لازم تتعرض بنفس الشكل ده.
        final bool isNewUser = res['is_new_user'] == true;

        if (isNewUser) {
          log('🎁 [WELCOME] جاري جلب المكافآت بعد تسجيل اشتراك جديد عبر السوشيال...');
          try {
            await rewardsStore.fetchRewards();
            log('🎁 [WELCOME] fetchRewards انتهت بنجاح — error=${rewardsStore.error} | rewards.length=${rewardsStore.rewards.length} | available.length=${rewardsStore.availableRewards.length}');
          } catch (e, st) {
            log('🎁 [WELCOME] ❌ fetchRewards رمت Exception: $e');
            log('🎁 [WELCOME] StackTrace: $st');
          }

          if (!mounted) {
            log('🎁 [WELCOME] ❌ الشاشة اتعملها dispose قبل ما نعرض الدايلوج (mounted=false)');
          } else if (rewardsStore.availableRewards.isNotEmpty) {
            log('🎁 [WELCOME] ✅ هنعرض الدايلوج دلوقتي — reward: ${rewardsStore.availableRewards.first.rewardTitle}');
            await RewardWelcomeDialog.show(context, rewardsStore.availableRewards.first);
            if (!mounted) return;
          } else {
            log('🎁 [WELCOME] ⚠️ availableRewards فاضية — مفيش دايلوج هيظهر');
          }
        }

        appStore.setLoading(false);

        const DashBoardScreen().launch(context, isNewTask: true);
      }).catchError((error) {
        appStore.setLoading(false);

        toast(error.toString());
      });
    }).catchError((error) {
      appStore.setLoading(false);

      toast(error.toString());
    });
  }

  void signInApi(req) async {
    appStore.setLoading(true);

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
      appStore.setLoggedIn(true);

      if (widget.userName != null && widget.userName!.isNotEmpty) {
        await setValue(IS_SOCIAL_LOGIN, true);
      }

      // ✅ v1.7.5-fix — بعد ما التوكن بقى صالح هنا (مسار التسجيل الجديد ثم
      // اللوجين التلقائي بعده)، نبعت الـ Player ID فوراً عشان أي إشعار بعد
      // كده (هدية الترحيب، تأكيد الاستخدام...) يوصل من أول استخدام للحساب.
      await savePlayerIdToServer();

      // ✅ هدية الترحيب: بيتم منحها من الباك إند بشكل متزامن داخل
      // wp_insert_user وقت createCustomer (قبل ما اللوجين ده يحصل أصلاً).
      // دلوقتي عندنا توكن صالح (newly set above)، فنقدر نسأل عن المكافآت
      // فعلياً ونعرض دايلوج ترحيبي لو لقينا حاجة متاحة، قبل ما نروح الداشبورد.
      log('🎁 [WELCOME] جاري جلب المكافآت بعد التسجيل...');
      try {
        await rewardsStore.fetchRewards();
        log('🎁 [WELCOME] fetchRewards انتهت بنجاح — error=${rewardsStore.error} | rewards.length=${rewardsStore.rewards.length} | available.length=${rewardsStore.availableRewards.length}');
      } catch (e, st) {
        log('🎁 [WELCOME] ❌ fetchRewards رمت Exception: $e');
        log('🎁 [WELCOME] StackTrace: $st');
      }

      appStore.setLoading(false);

      if (!mounted) {
        log('🎁 [WELCOME] ❌ الشاشة اتعملها dispose قبل ما نعرض الدايلوج (mounted=false)');
        return;
      }

      if (rewardsStore.availableRewards.isNotEmpty) {
        log('🎁 [WELCOME] ✅ هنعرض الدايلوج دلوقتي — reward: ${rewardsStore.availableRewards.first.rewardTitle}');
        // ✅ استخدام الكومبوننت الموحّد بدل الكود المحلي المكرر
        await RewardWelcomeDialog.show(context, rewardsStore.availableRewards.first);
        if (!mounted) return;
      } else {
        log('🎁 [WELCOME] ⚠️ availableRewards فاضية — مفيش دايلوج هيظهر');
      }

      const DashBoardScreen().launch(context, isNewTask: true);
    }).catchError((error) {
      print("Error$error");
      appStore.setLoading(false);
      toast(error.toString());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: mTop(context, "", showBack: true) as PreferredSizeWidget?,
        bottomNavigationBar: RichTextWidget(
          textAlign: TextAlign.center,
          list: [
            TextSpan(text: appLocalization.translate('lbl_already_have_account'), style: primaryTextStyle(size: 14)),
            const TextSpan(text: "  "),
            TextSpan(text: appLocalization.translate('lbl_sign_in')!, style: primaryTextStyle(color: primaryColor))
          ],
        ).onTap(() {
          finish(context);
        }).paddingAll(16),
        body: BodyCornerWidget(
          child: Stack(
            children: <Widget>[
              Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      50.height,
                      Text(appLocalization.translate('lbl_create_account')!, style: boldTextStyle(color: primaryColor, size: 26)),
                      24.height,
                      Row(
                        children: [
                          Expanded(
                            child: EditText(
                                hintText: appLocalization.translate('hint_first_name'),
                                isPassword: false,
                                mController: fNameCont,
                                validator: (String? v) {
                                  if (v!.trim().isEmpty) return appLocalization.translate('error_first_name_required');
                                  if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v.trim())) return appLocalization.translate('error_only_alphabet');
                                  return null;
                                }),
                          ),
                          8.width,
                          Expanded(
                            child: EditText(
                                hintText: appLocalization.translate('hint_last_name'),
                                isPassword: false,
                                mController: lNameCont,
                                validator: (String? v) {
                                  if (v!.trim().isEmpty) return appLocalization.translate('error_last_name_required');
                                  if (!RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(v.trim())) return appLocalization.translate('error_only_alphabet');
                                  return null;
                                }),
                          )
                        ],
                      ),
                      16.height,
                      EditText(
                          hintText: appLocalization.translate('lbl_email'),
                          isPassword: false,
                          mController: emailCont,
                          validator: (String? v) {
                            if (v!.trim().isEmpty) return appLocalization.translate('error_email_required');
                            if (!v.trim().validateEmail()) return appLocalization.translate('error_wrong_email');
                            return null;
                          }),
                      16.height,
                      EditText(
                          hintText: appLocalization.translate('hint_Username'),
                          isPassword: false,
                          mController: usernameCont,
                          validator: (v) {
                            if (v.trim().isEmpty) return appLocalization.translate('error_username_require');
                            return null;
                          }).visible(widget.userName.isEmptyOrNull),
                      16.height,
                      EditText(
                          hintText: appLocalization.translate('hint_password'),
                          isPassword: true,
                          isSecure: true,
                          mController: passwordCont,
                          validator: (v) {
                            if (v.trim().isEmpty) return appLocalization.translate('error_pwd_require');
                            return null;
                          }).visible(widget.userName.isEmptyOrNull),
                      16.height.visible(widget.userName.isEmptyOrNull),
                      EditText(
                          hintText: appLocalization.translate('hint_confirm_password'),
                          isPassword: true,
                          isSecure: true,
                          mController: confirmPasswordCont,
                          validator: (v) {
                            if (v.trim().isEmpty) return appLocalization.translate('error_confirm_pwd_required');
                            if (confirmPasswordCont.text != passwordCont.text) return appLocalization.translate('error_pwd_not_match');
                            return null;
                          }).visible(widget.userName.isEmptyOrNull),
                      30.height,
                      AppButton(
                          width: context.width(),
                          text: appLocalization.translate('lbl_sign_up_link'),
                          textStyle: primaryTextStyle(color: white),
                          color: primaryColor,
                          onTap: () {
                            signUpApi();
                          }),
                      16.height
                    ],
                  ),
                ),
              ),
              Observer(builder: (_) => mProgress().center().visible(appStore.isLoading)),
            ],
          ),
        ),
      ),
    );
  }
}