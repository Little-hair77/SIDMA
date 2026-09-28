import 'package:flutter/material.dart';

/// Paleta oficial do SIDMA — usada em todas as telas para manter consistência
/// visual, agora com suporte a modo claro e escuro.
/// 
/// Os valores do modo claro replicam exatamente a paleta que já existia
/// espalhada pelas telas (tons de slate + emerald).
class AppColors extends ThemeExtension<AppColors> {
  final Color fundo;
  final Color superficie;
  final Color superficieAlt;
  final Color borda;
  final Color textoPrimario;
  final Color textoSecundario;
  final Color textoDesabilitado;

  final Color primario;
  final Color primarioEscuro;
  final Color primarioSuave;

  final Color destaque; // navy dos headers/appbars

  final Color erro;
  final Color erroFundo;
  final Color alerta;
  final Color alertaFundo;
  final Color info;
  final Color infoFundo;
  final Color rosa;
  final Color rosaFundo;
  final Color laranja;

  const AppColors({
    required this.fundo,
    required this.superficie,
    required this.superficieAlt,
    required this.borda,
    required this.textoPrimario,
    required this.textoSecundario,
    required this.textoDesabilitado,
    required this.primario,
    required this.primarioEscuro,
    required this.primarioSuave,
    required this.destaque,
    required this.erro,
    required this.erroFundo,
    required this.alerta,
    required this.alertaFundo,
    required this.info,
    required this.infoFundo,
    required this.rosa,
    required this.rosaFundo,
    required this.laranja,
  });

  /// Paleta do modo claro — mesmos valores que já estavam espalhados pelas
  /// telas antes da introdução do tema (nenhuma mudança visual no claro).
  static const AppColors claro = AppColors(
    fundo: Color(0xFFF8FAFC),
    superficie: Colors.white,
    superficieAlt: Color(0xFFF1F5F9),
    borda: Color(0xFFE2E8F0),
    textoPrimario: Color(0xFF0F172A),
    textoSecundario: Color(0xFF64748B),
    textoDesabilitado: Color(0xFF94A3B8),
    primario: Color(0xFF10B981),
    primarioEscuro: Color(0xFF059669),
    primarioSuave: Color(0xFFECFDF5),
    destaque: Color(0xFF1E293B),
    erro: Color(0xFFDC2626),
    erroFundo: Color(0xFFFEF2F2),
    alerta: Color(0xFFD97706),
    alertaFundo: Color(0xFFFFFBEB),
    info: Color(0xFF2563EB),
    infoFundo: Color(0xFFEFF6FF),
    rosa: Color(0xFFDB2777),
    rosaFundo: Color(0xFFFCE7F3),
    laranja: Color(0xFFF97316),
  );

  /// Paleta do modo escuro — fundo e superfícies invertidos (slate escuro),
  /// cores de destaque/status ajustadas para manter contraste e legibilidade.
  static const AppColors escuro = AppColors(
    fundo: Color(0xFF0F172A),
    superficie: Color(0xFF1E293B),
    superficieAlt: Color(0xFF334155),
    borda: Color(0xFF334155),
    textoPrimario: Color(0xFFF1F5F9),
    textoSecundario: Color(0xFF94A3B8),
    textoDesabilitado: Color(0xFF64748B),
    primario: Color(0xFF10B981),
    primarioEscuro: Color(0xFF34D399),
    primarioSuave: Color(0xFF064E3B),
    destaque: Color(0xFF1E293B),
    erro: Color(0xFFF87171),
    erroFundo: Color(0xFF450A0A),
    alerta: Color(0xFFFBBF24),
    alertaFundo: Color(0xFF451A03),
    info: Color(0xFF60A5FA),
    infoFundo: Color(0xFF172554),
    rosa: Color(0xFFF472B6),
    rosaFundo: Color(0xFF4A044E),
    laranja: Color(0xFFFB923C),
  );

  /// Atalho para usar dentro de qualquer widget: `AppColors.of(context).primario`
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.claro;
  }

  @override
  AppColors copyWith({
    Color? fundo,
    Color? superficie,
    Color? superficieAlt,
    Color? borda,
    Color? textoPrimario,
    Color? textoSecundario,
    Color? textoDesabilitado,
    Color? primario,
    Color? primarioEscuro,
    Color? primarioSuave,
    Color? destaque,
    Color? erro,
    Color? erroFundo,
    Color? alerta,
    Color? alertaFundo,
    Color? info,
    Color? infoFundo,
    Color? rosa,
    Color? rosaFundo,
    Color? laranja,
  }) {
    return AppColors(
      fundo: fundo ?? this.fundo,
      superficie: superficie ?? this.superficie,
      superficieAlt: superficieAlt ?? this.superficieAlt,
      borda: borda ?? this.borda,
      textoPrimario: textoPrimario ?? this.textoPrimario,
      textoSecundario: textoSecundario ?? this.textoSecundario,
      textoDesabilitado: textoDesabilitado ?? this.textoDesabilitado,
      primario: primario ?? this.primario,
      primarioEscuro: primarioEscuro ?? this.primarioEscuro,
      primarioSuave: primarioSuave ?? this.primarioSuave,
      destaque: destaque ?? this.destaque,
      erro: erro ?? this.erro,
      erroFundo: erroFundo ?? this.erroFundo,
      alerta: alerta ?? this.alerta,
      alertaFundo: alertaFundo ?? this.alertaFundo,
      info: info ?? this.info,
      infoFundo: infoFundo ?? this.infoFundo,
      rosa: rosa ?? this.rosa,
      rosaFundo: rosaFundo ?? this.rosaFundo,
      laranja: laranja ?? this.laranja,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      fundo: Color.lerp(fundo, other.fundo, t)!,
      superficie: Color.lerp(superficie, other.superficie, t)!,
      superficieAlt: Color.lerp(superficieAlt, other.superficieAlt, t)!,
      borda: Color.lerp(borda, other.borda, t)!,
      textoPrimario: Color.lerp(textoPrimario, other.textoPrimario, t)!,
      textoSecundario: Color.lerp(textoSecundario, other.textoSecundario, t)!,
      textoDesabilitado: Color.lerp(textoDesabilitado, other.textoDesabilitado, t)!,
      primario: Color.lerp(primario, other.primario, t)!,
      primarioEscuro: Color.lerp(primarioEscuro, other.primarioEscuro, t)!,
      primarioSuave: Color.lerp(primarioSuave, other.primarioSuave, t)!,
      destaque: Color.lerp(destaque, other.destaque, t)!,
      erro: Color.lerp(erro, other.erro, t)!,
      erroFundo: Color.lerp(erroFundo, other.erroFundo, t)!,
      alerta: Color.lerp(alerta, other.alerta, t)!,
      alertaFundo: Color.lerp(alertaFundo, other.alertaFundo, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoFundo: Color.lerp(infoFundo, other.infoFundo, t)!,
      rosa: Color.lerp(rosa, other.rosa, t)!,
      rosaFundo: Color.lerp(rosaFundo, other.rosaFundo, t)!,
      laranja: Color.lerp(laranja, other.laranja, t)!,
    );
  }
}