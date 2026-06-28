import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/services/shared_preferences_singleton.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';
import '../../services/payment_service.dart';
import 'payment_success_page.dart';

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buf.write('/');
      buf.write(digits[i]);
    }
    final s = buf.toString();
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class CheckoutPage extends StatefulWidget {
  final String? itemId;
  final String? itemType;
  final String? itemTitle;
  final String? itemSubject;
  final double? itemPrice;
  final double? itemOldPrice;
  final String? teacherName;
  final String? teacherAvatar;
  final Color? itemColor;
  final List<Color>? itemGradient;

  const CheckoutPage({
    super.key,
    this.itemId,
    this.itemType,
    this.itemTitle,
    this.itemSubject,
    this.itemPrice,
    this.itemOldPrice,
    this.teacherName,
    this.teacherAvatar,
    this.itemColor,
    this.itemGradient,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _paymentService = PaymentService();

  bool _authChecked = false;
  bool _loading = false;
  bool _success = false;
  String? _error;
  String _paymentMethod = 'card';
  String _promoCode = '';
  bool _promoApplied = false;
  bool _promoLoading = false;
  double _discount = 0;
  String? _orderId;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  double get _basePrice => widget.itemPrice ?? 0;
  double get _total => _basePrice - (_basePrice * _discount / 100);
  Color get _color => widget.itemColor ?? ExploreColors.primary;
  List<Color> get _gradient => widget.itemGradient ?? ExploreColors.blueGradient;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final token = Prefs.getString('token');
    if (token == null || widget.itemId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (token == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
            );
          }
          Navigator.pop(context);
        }
      });
      return;
    }
    _loadUserData();
    setState(() => _authChecked = true);
  }

  void _loadUserData() {
    try {
      final raw = Prefs.getString('user');
      if (raw != null) {
        final user = jsonDecode(raw) as Map<String, dynamic>;
        _nameController.text = user['name'] as String? ?? '';
        _emailController.text = user['email'] as String? ?? '';
        _phoneController.text = user['phone'] as String? ?? '';
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _applyPromo() async {
    if (_promoCode.trim().isEmpty) return;
    setState(() => _promoLoading = true);
    try {
      final data = await _paymentService.validatePromoCode(_promoCode.trim());
      setState(() {
        _promoApplied = true;
        _discount = (data['discount'] as num?)?.toDouble() ?? 0;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'كود الخصم غير صحيح';
        _promoApplied = false;
        _discount = 0;
      });
    } finally {
      setState(() => _promoLoading = false);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        _error = 'برجاء إدخال جميع البيانات الشخصية';
        _loading = false;
      });
      return;
    }

    if (_paymentMethod == 'card') {
      final cardClean = _cardNumberController.text.replaceAll(' ', '');
      if (_cardNumberController.text.isEmpty || _expiryController.text.isEmpty || _cvvController.text.isEmpty) {
        setState(() {
          _error = 'برجاء إدخال جميع بيانات البطاقة';
          _loading = false;
        });
        return;
      }
      if (cardClean.length != 16) {
        setState(() {
          _error = 'رقم البطاقة يجب أن يكون 16 رقم';
          _loading = false;
        });
        return;
      }
      if (_cvvController.text.length != 3) {
        setState(() {
          _error = 'CVV يجب أن يكون 3 أرقام';
          _loading = false;
        });
        return;
      }
    }

    try {
      final data = await _paymentService.processPayment(
        itemId: widget.itemId ?? '',
        itemType: widget.itemType ?? 'course',
        paymentMethod: _paymentMethod,
        promoCode: _promoApplied ? _promoCode.trim() : null,
        totalAmount: _total,
      );
      _orderId = data['orderId'] as String?;
      setState(() => _success = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentSuccessPage(
                itemTitle: widget.itemTitle ?? '',
                total: _total,
                orderId: _orderId ?? '',
                itemColor: _color,
              ),
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في عملية الدفع. برجاء المحاولة مرة أخرى.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (!_authChecked) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: _color),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isDark),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  // ── Payment Form ──
                  _buildPersonalInfoCard(isDark),
                  const SizedBox(height: 24),
                  _buildPaymentMethodCard(isDark),
                  const SizedBox(height: 8),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildAlert(isDark),
                  ],
                  if (_success) ...[
                    const SizedBox(height: 16),
                    _buildSuccessAlert(isDark),
                  ],
                  const SizedBox(height: 16),
                  _buildSubmitButton(isDark),
                  const SizedBox(height: 24),
                  // ── Order Summary ──
                  _buildItemCard(isDark),
                  const SizedBox(height: 24),
                  _buildPromoCodeCard(isDark),
                  const SizedBox(height: 24),
                  _buildSecurityBadge(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: ExploreColors.mainGradient),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40, right: -40,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: -20,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    Text(
                      'إتمام الشراء',
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        fontFamily: 'Cairo', color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'أنت على بعد خطوة واحدة من بدء رحلتك التعليمية',
                      style: TextStyle(
                        fontSize: 13, fontFamily: 'Cairo',
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PERSONAL INFO CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildPersonalInfoCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _card(
        isDark,
        children: [
          _sectionHeader(isDark, Icons.person_rounded, 'البيانات الشخصية', ExploreColors.blueGradient),
          const SizedBox(height: 16),
          _buildTextField('الاسم الكامل', _nameController, isDark),
          const SizedBox(height: 12),
          _buildTextField('البريد الإلكتروني', _emailController, isDark, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildTextField('رقم الهاتف', _phoneController, isDark, keyboardType: TextInputType.phone),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PAYMENT METHOD CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildPaymentMethodCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _card(
        isDark,
        children: [
          _sectionHeader(isDark, Icons.credit_card_rounded, 'طريقة الدفع', ExploreColors.purpleGradient),
          const SizedBox(height: 16),
          _paymentOption('card', 'بطاقة ائتمان / خصم', Icons.credit_card_rounded, isDark),
          const SizedBox(height: 8),
          _paymentOption(
            'fawry', 'الدفع عند الاستلام (فوري / محافظ إلكترونية)',
            Icons.account_balance_wallet_rounded, isDark,
          ),
          if (_paymentMethod == 'card') ...[
            const SizedBox(height: 16),
            Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            _buildTextField(
              'رقم البطاقة', _cardNumberController, isDark,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CardNumberFormatter(),
              ],
              hint: '1234 5678 9012 3456',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    'تاريخ الانتهاء', _expiryController, isDark,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ExpiryFormatter(),
                    ],
                    hint: 'MM/YY',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'CVV', _cvvController, isDark,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    hint: '123',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Text(
                    'جميع المعاملات مشفرة وآمنة بنسبة 100%',
                    style: TextStyle(
                      fontSize: 11, fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0284C7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ALERTS
  // ─────────────────────────────────────────────────────────────

  Widget _buildAlert(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessAlert(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 20, color: Color(0xFF059669)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'تمت عملية الشراء بنجاح! جاري التحويل...',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: Color(0xFF059669)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SUBMIT BUTTON
  // ─────────────────────────────────────────────────────────────

  Widget _buildSubmitButton(bool isDark) {
    final disabled = _loading || _success;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: disabled
            ? (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))
            : null,
        child: Ink(
          decoration: disabled
              ? null
              : BoxDecoration(
                  gradient: const LinearGradient(colors: ExploreColors.mainGradient),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4D2563EB),
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: disabled ? null : _submit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _loading
                    ? _buttonRow(
                        const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        'جاري المعالجة...',
                        Colors.white,
                      )
                    : _success
                        ? Text(
                            'تم الشراء بنجاح',
                            style: TextStyle(
                              fontFamily: 'Cairo', fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                          )
                        : _buttonRow(
                            const Icon(Icons.shopping_cart_rounded, size: 22, color: Colors.white),
                            'ادفع الآن ${_total.toInt()} جنيه',
                            Colors.white,
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttonRow(Widget icon, String text, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Text(text, style: TextStyle(
          fontFamily: 'Cairo', fontSize: 17,
          fontWeight: FontWeight.w900, color: textColor,
        )),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ITEM CARD (Order Summary)
  // ─────────────────────────────────────────────────────────────

  Widget _buildItemCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            // Gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: LinearGradient(colors: _gradient)),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.itemTitle ?? '',
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo', color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.itemSubject != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.itemSubject!,
                        style: const TextStyle(fontSize: 11, fontFamily: 'Cairo', color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Teacher row
            if (widget.teacherName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _color,
                        backgroundImage: widget.teacherAvatar != null
                            ? NetworkImage(widget.teacherAvatar!)
                            : null,
                        child: widget.teacherAvatar == null
                            ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.teacherName!,
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Price breakdown
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _priceLine('السعر الأساسي', '${_basePrice.toInt()} جنيه', isDark),
                  if (widget.itemOldPrice != null && widget.itemOldPrice! > _basePrice)
                    _priceLine(
                      'الخصم',
                      '-${(widget.itemOldPrice! - _basePrice).toInt()} جنيه',
                      isDark, valueColor: ExploreColors.success,
                    ),
                  if (_promoApplied)
                    _priceLine(
                      'كود الخصم (${_discount.toInt()}%)',
                      '-${(_basePrice * _discount / 100).toInt()} جنيه',
                      isDark, valueColor: ExploreColors.success,
                    ),
                  Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${_total.toInt()} جنيه',
                        style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo', color: _color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // PROMO CODE CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildPromoCodeCard(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _card(
        isDark,
        padding: 20,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer_rounded, size: 20,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              const SizedBox(width: 10),
              Text(
                'هل لديك كود خصم؟',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'أدخل الكود', null, isDark,
                  onChanged: (v) => _promoCode = v,
                  enabled: !_promoApplied,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_promoApplied || _promoCode.trim().isEmpty)
                      ? null
                      : _applyPromo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _promoApplied ? null : ExploreColors.primary,
                    foregroundColor: _promoApplied ? null : Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                    disabledForegroundColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: _promoLoading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(_promoApplied ? Icons.check_circle_rounded : Icons.check,
                          size: 20),
                ),
              ),
            ],
          ),
          if (_promoApplied) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 6),
                  Text(
                    'تم تطبيق كود الخصم بنجاح! خصم ${_discount.toInt()}%',
                    style: const TextStyle(fontSize: 12, fontFamily: 'Cairo', color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SECURITY BADGE
  // ─────────────────────────────────────────────────────────────

  Widget _buildSecurityBadge(bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: ExploreColors.greenGradient),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_rounded, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'دفع آمن 100%',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo', color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'جميع المعاملات مشفرة بالكامل',
                    style: TextStyle(
                      fontSize: 11, fontFamily: 'Cairo',
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'جميع معلومات الدفع محمية ومشفرة',
                style: TextStyle(
                  fontSize: 11, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  Widget _card(bool isDark, {required List<Widget> children, double padding = 20}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _sectionHeader(bool isDark, IconData icon, String title, List<Color> gradient) {
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _paymentOption(String value, String label, IconData icon, bool isDark) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? ExploreColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? (isDark ? ExploreColors.primary.withValues(alpha: 0.1) : const Color(0xFFEFF6FF))
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? ExploreColors.primary : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 10),
            Icon(icon, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13, fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceLine(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
              color: valueColor ?? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController? controller,
    bool isDark, {
    TextInputType? keyboardType,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? hint,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      enabled: enabled,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 14,
        fontFamily: 'Cairo',
        color: enabled
            ? (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))
            : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontFamily: 'Cairo', fontSize: 13,
          color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Cairo', fontSize: 13,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}
