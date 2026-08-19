import 'package:flutter/material.dart';

import '../../models/viaje.dart';
import '../../services/viaje_service.dart';
import '../../utils/formato.dart';
import '../../utils/validadores.dart';

/// Formulario de alta y edición de viajes.
///
/// Una misma pantalla resuelve dos operaciones del CRUD:
/// * **Agregar** cuando se abre sin argumentos.
/// * **Actualizar** cuando recibe un [viaje] existente.
class FormularioViajeScreen extends StatefulWidget {
  const FormularioViajeScreen({super.key, this.viaje});

  /// Viaje a modificar. Si es `null`, la pantalla opera en modo alta.
  final Viaje? viaje;

  bool get esEdicion => viaje != null;

  @override
  State<FormularioViajeScreen> createState() => _FormularioViajeScreenState();
}

class _FormularioViajeScreenState extends State<FormularioViajeScreen> {
  final _formulario = GlobalKey<FormState>();
  final _servicio = ViajeService();

  late final TextEditingController _titulo;
  late final TextEditingController _destino;
  late final TextEditingController _pais;
  late final TextEditingController _presupuesto;
  late final TextEditingController _notas;

  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late EstadoViaje _estado;
  late String _moneda;

  bool _guardando = false;
  String? _error;

  static const List<String> _monedas = ['MXN', 'USD', 'EUR', 'JPY', 'CAD'];

  @override
  void initState() {
    super.initState();
    final v = widget.viaje ?? Viaje.nuevo();

    _titulo = TextEditingController(text: v.titulo);
    _destino = TextEditingController(text: v.destino);
    _pais = TextEditingController(text: v.pais);
    _presupuesto = TextEditingController(
      text: v.presupuesto == 0 ? '' : v.presupuesto.toStringAsFixed(2),
    );
    _notas = TextEditingController(text: v.notas ?? '');

    _fechaInicio = v.fechaInicio;
    _fechaFin = v.fechaFin;
    _estado = v.estado;
    _moneda = v.moneda;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _destino.dispose();
    _pais.dispose();
    _presupuesto.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 10),
      helpText: esInicio ? 'Fecha de inicio' : 'Fecha de regreso',
    );

    if (elegida == null) return;

    setState(() {
      if (esInicio) {
        _fechaInicio = elegida;
        // La fecha de regreso nunca puede quedar antes de la de salida.
        if (_fechaFin.isBefore(_fechaInicio)) _fechaFin = _fechaInicio;
      } else {
        _fechaFin = elegida.isBefore(_fechaInicio) ? _fechaInicio : elegida;
      }
    });
  }

  Future<void> _guardar() async {
    setState(() => _error = null);

    if (!_formulario.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    final viaje = Viaje(
      id: widget.viaje?.id ?? '',
      titulo: _titulo.text,
      destino: _destino.text,
      pais: _pais.text,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      presupuesto: double.tryParse(_presupuesto.text.replaceAll(',', '')) ?? 0,
      moneda: _moneda,
      estado: _estado,
      notas: _notas.text.trim().isEmpty ? null : _notas.text,
      imagenUrl: widget.viaje?.imagenUrl,
    );

    try {
      if (widget.esEdicion) {
        await _servicio.actualizar(viaje);
      } else {
        await _servicio.agregar(viaje);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ViajeException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar viaje' : 'Nuevo viaje'),
      ),
      body: SafeArea(
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: esquema.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 20, color: esquema.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: esquema.onErrorContainer,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              const _Seccion('Información del viaje'),

              TextFormField(
                controller: _titulo,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                maxLength: Validadores.maxTitulo,
                decoration: const InputDecoration(
                  labelText: 'Título del viaje',
                  hintText: 'Vacaciones en Japón',
                  prefixIcon: Icon(Icons.flight_takeoff),
                ),
                validator: (v) => Validadores.obligatorio(
                  v,
                  'un título',
                  max: Validadores.maxTitulo,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _destino,
                      enabled: !_guardando,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        hintText: 'Tokio',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (v) =>
                          Validadores.obligatorio(v, 'la ciudad', max: 60),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pais,
                      enabled: !_guardando,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'País',
                        hintText: 'Japón',
                        prefixIcon: Icon(Icons.public),
                      ),
                      validator: (v) =>
                          Validadores.obligatorio(v, 'el país', max: 60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _Seccion('Fechas'),

              Row(
                children: [
                  Expanded(
                    child: _SelectorFecha(
                      etiqueta: 'Salida',
                      fecha: _fechaInicio,
                      habilitado: !_guardando,
                      alTocar: () => _elegirFecha(esInicio: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SelectorFecha(
                      etiqueta: 'Regreso',
                      fecha: _fechaFin,
                      habilitado: !_guardando,
                      alTocar: () => _elegirFecha(esInicio: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Duración: ${_fechaFin.difference(_fechaInicio).inDays + 1} días',
                  style: TextStyle(
                    color: esquema.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _Seccion('Presupuesto'),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _presupuesto,
                      enabled: !_guardando,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monto estimado',
                        hintText: '45000',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      validator: (v) => Validadores.monto(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _moneda,
                      decoration: const InputDecoration(labelText: 'Moneda'),
                      items: [
                        for (final m in _monedas)
                          DropdownMenuItem(value: m, child: Text(m)),
                      ],
                      onChanged: _guardando
                          ? null
                          : (v) => setState(() => _moneda = v ?? 'MXN'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const _Seccion('Estado'),

              SegmentedButton<EstadoViaje>(
                segments: [
                  for (final e in EstadoViaje.values)
                    ButtonSegment(value: e, label: Text(e.etiqueta)),
                ],
                selected: {_estado},
                onSelectionChanged: _guardando
                    ? null
                    : (s) => setState(() => _estado = s.first),
              ),
              const SizedBox(height: 24),

              const _Seccion('Notas'),

              TextFormField(
                controller: _notas,
                enabled: !_guardando,
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Documentos, recordatorios, contactos...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Icon(widget.esEdicion ? Icons.save : Icons.add),
                label: Text(
                  widget.esEdicion ? 'Guardar cambios' : 'Agregar viaje',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo);
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({
    required this.etiqueta,
    required this.fecha,
    required this.habilitado,
    required this.alTocar,
  });

  final String etiqueta;
  final DateTime fecha;
  final bool habilitado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return InkWell(
      onTap: habilitado ? alTocar : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: etiqueta,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          Formato.fechaCorta(fecha),
          style: TextStyle(fontSize: 15, color: esquema.onSurface),
        ),
      ),
    );
  }
}
