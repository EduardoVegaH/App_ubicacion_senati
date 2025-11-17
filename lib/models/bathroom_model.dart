import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BathroomStatus {
  operativo,
  en_limpieza,
  inoperativo,
}

extension BathroomStatusExtension on BathroomStatus {
  String get label {
    switch (this) {
      case BathroomStatus.operativo:
        return 'Operativo';
      case BathroomStatus.en_limpieza:
        return 'En Limpieza';
      case BathroomStatus.inoperativo:
        return 'Inoperativo';
    }
  }

  IconData get icon {
    switch (this) {
      case BathroomStatus.operativo:
        return Icons.check_circle;
      case BathroomStatus.en_limpieza:
        return Icons.cleaning_services;
      case BathroomStatus.inoperativo:
        return Icons.error;
    }
  }

  Color get color {
    switch (this) {
      case BathroomStatus.operativo:
        return const Color(0xFF3D79FF); // Celeste/Azul claro (como "Presente")
      case BathroomStatus.en_limpieza:
        return const Color(0xFFCBA761); // Amarillo beige
      case BathroomStatus.inoperativo:
        return const Color(0xFF622222); // Guinda oscuro (como "Ausente")
    }
  }
}

class BathroomModel {
  final String id;
  final String nombre;
  final int piso;
  final BathroomStatus estado;
  final String? tipo; // "hombres", "mujeres", "mixto"
  final String? usuarioLimpiezaId;
  final String? usuarioLimpiezaNombre;
  final DateTime? inicioLimpieza;
  final DateTime? finLimpieza;
  final DateTime? ultimaActualizacion;

  BathroomModel({
    required this.id,
    required this.nombre,
    required this.piso,
    required this.estado,
    this.tipo,
    this.usuarioLimpiezaId,
    this.usuarioLimpiezaNombre,
    this.inicioLimpieza,
    this.finLimpieza,
    this.ultimaActualizacion,
  });

  // Convertir de Firestore a BathroomModel
  factory BathroomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BathroomModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      piso: data['piso'] ?? 0,
      estado: BathroomStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['estado'],
        orElse: () => BathroomStatus.operativo,
      ),
      tipo: data['tipo'],
      usuarioLimpiezaId: data['usuarioLimpiezaId'],
      usuarioLimpiezaNombre: data['usuarioLimpiezaNombre'],
      inicioLimpieza: data['inicioLimpieza'] != null
          ? (data['inicioLimpieza'] as Timestamp).toDate()
          : null,
      finLimpieza: data['finLimpieza'] != null
          ? (data['finLimpieza'] as Timestamp).toDate()
          : null,
      ultimaActualizacion: data['ultimaActualizacion'] != null
          ? (data['ultimaActualizacion'] as Timestamp).toDate()
          : null,
    );
  }

  // Convertir BathroomModel a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nombre': nombre,
      'piso': piso,
      'estado': estado.toString().split('.').last,
      'tipo': tipo,
      'usuarioLimpiezaId': usuarioLimpiezaId,
      'usuarioLimpiezaNombre': usuarioLimpiezaNombre,
      'inicioLimpieza': inicioLimpieza != null
          ? Timestamp.fromDate(inicioLimpieza!)
          : null,
      'finLimpieza': finLimpieza != null
          ? Timestamp.fromDate(finLimpieza!)
          : null,
      'ultimaActualizacion': Timestamp.now(),
    };
  }

  // Crear una copia con cambios
  BathroomModel copyWith({
    String? id,
    String? nombre,
    int? piso,
    BathroomStatus? estado,
    String? tipo,
    String? usuarioLimpiezaId,
    String? usuarioLimpiezaNombre,
    DateTime? inicioLimpieza,
    DateTime? finLimpieza,
    DateTime? ultimaActualizacion,
  }) {
    return BathroomModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      piso: piso ?? this.piso,
      estado: estado ?? this.estado,
      tipo: tipo ?? this.tipo,
      usuarioLimpiezaId: usuarioLimpiezaId ?? this.usuarioLimpiezaId,
      usuarioLimpiezaNombre: usuarioLimpiezaNombre ?? this.usuarioLimpiezaNombre,
      inicioLimpieza: inicioLimpieza ?? this.inicioLimpieza,
      finLimpieza: finLimpieza ?? this.finLimpieza,
      ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
    );
  }
}

