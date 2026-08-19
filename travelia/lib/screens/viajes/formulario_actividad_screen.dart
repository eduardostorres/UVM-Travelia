import 'package:flutter/material.dart';

import '../../models/actividad.dart';
import '../../services/viaje_service.dart';
import '../../utils/formato.dart';
import '../../utils/validadores.dart';

/// Alta y edición de actividades del itinerario.
///
/// Opera sobre la subcolección
/// `users/{uid}/viajes/{viajeId}/actividades`, demostrando un CRUD anidado
/// dentro del documento principal.
class FormularioActividadScreen extends StatefulWidget {
  const FormularioActividadScreen({
    super.key,
    required this.viajeId,
    this.actividad,
    this.fechaSugerida,
  });

  final String viajeId;
  final Actividad? actividad;

  /// Fecha propuesta al dar de alta una actividad. Se usa la fecha de salida
  /// del viaje, que es mas util que la fecha actual: casi siempre el viaje
  /// ocurre en el futuro y la actividad pertenece a esos dias.
  final DateTime? fechaSugerida;

  bool get esEdicion => actividad != null;

  @override
  State<FormularioActividadScreen> createState() =>
      _FormularioActividadScreenState();
}

class _FormularioActividadScreenState extends State<FormularioActividadScreen> {
  final _formulario = GlobalKey<FormState>();
  final _servicio = ViajeService();

  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  late final TextEditingController _ubicacion;
  late final TextEditingController _costo;

  late DateTime _fecha;
  late TimeOfDay _hora;
  late CategoriaActividad _categoria;
  late bool _completada;

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.actividad;

    _titulo = TextEditingController(text: a?.titulo ?? '');
    _descripcion = TextEditingController(text: a?.descripcion ?? '');
    _ubicacion = TextEditingController(text: a?.ubicacion ?? '');
    _costo = TextEditingController(
      text: (a?.costo ?? 0) == 0 ? '' : a!.costo.toStringAsFixed(2),
    );

    _fecha = a?.fecha ?? widget.fechaSugerida ?? DateTime.now();
    _categoria = a?.categoria ?? CategoriaActividad.atraccion;
    _completada = a?.completada ?? false;

    final partes = (a?.hora ?? '09:00').split(':');
    _hora = TimeOfDay(
      hour: int.tryParse(partes.first) ?? 9,
      minute: int.tryParse(partes.last) ?? 0,
    );
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    _ubicacion.dispose();
    _costo.dispose();
    super.dispose();
  }

  String get _horaTexto =>
      '${_hora.hour.toString().padLeft(2, '0')}:'
      '${_hora.minute.toString().padLeft(2, '0')}';

  Future<void> _elegirFecha() async {
    final f = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (f != null) setState(() => _fecha = f);
  }

  Future<void> _elegirHora() async {
    final h = await showTimePicker(context: context, initialTime: _hora);
    if (h != null) setState(() => _hora = h);
  }

  Future<void> _guardar() async {
    setState(() => _error = null);
    if (!_formulario.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);

    final actividad = Actividad(
      id: widget.actividad?.id ?? '',
      titulo: _titulo.text,
      fecha: _fecha,
      hora: _horaTexto,
      categoria: _categoria,
      costo: double.tryParse(_costo.text.replaceAll(',', '')) ?? 0,
      descripcion: _descripcion.text.trim().isEmpty ? null : _descripcion.text,
      ubicacion: _ubicacion.text.trim().isEmpty ? null : _ubicacion.text,
      completada: _completada,
    );

    try {
      if (widget.esEdicion) {
        await _servicio.actualizarActividad(widget.viajeId, actividad);
      } else {
        await _servicio.agregarActividad(widget.viajeId, actividad);
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
        title: Text(widget.esEdicion ? 'Editar actividad' : 'Nueva actividad'),
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
                  child: Text(
                    _error!,
                    style: TextStyle(color: esquema.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              TextFormField(
                controller: _titulo,
                enabled: !_guardando,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Actividad',
                  hintText: 'Visita al Templo Senso-ji',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
                validator: (v) =>
                    Validadores.obligatorio(v, 'un nombre de actividad'),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<CategoriaActividad>(
                initialValue: _categoria,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final c in CategoriaActividad.values)
                    DropdownMenuItem(value: c, child: Text(c.etiqueta)),
                ],
                onChanged: _guardando
                    ? null
                    : (v) => setState(
                          () => _categoria = v ?? CategoriaActividad.otro,
                        ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _guardando ? null : _elegirFecha,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(Formato.fechaCorta(_fecha)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _guardando ? null : _elegirHora,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        child: Text(_horaTexto),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _ubicacion,
                enabled: !_guardando,
                decoration: const InputDecoration(
                  labelText: 'Ubicación (opcional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _costo,
                enabled: !_guardando,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Costo estimado (opcional)',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) => Validadores.monto(v, obligatorio: false),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descripcion,
                enabled: !_guardando,
                maxLines: 3,
                maxLength: 300,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  alignLabelWithHint: true,
                ),
              ),

              SwitchListTile(
                value: _completada,
                onChanged: _guardando
                    ? null
                    : (v) => setState(() => _completada = v),
                title: const Text('Marcar como completada'),
                contentPadding: EdgeInsets.zero,
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
                  widget.esEdicion ? 'Guardar cambios' : 'Agregar actividad',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
