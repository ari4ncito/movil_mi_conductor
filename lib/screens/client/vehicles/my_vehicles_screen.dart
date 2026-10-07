import 'package:flutter/material.dart';

import '/models/vehicle.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/vehiculo_service.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
	const MyVehiclesScreen({super.key});

	@override
	State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
	List<dynamic> _vehicles = [];
	bool _isLoading = true;
	String? _clienteId;

	@override
	void initState() {
		super.initState();
		_cargarVehiculos();
	}

	Future<void> _cargarVehiculos() async {
		setState(() => _isLoading = true);
		try {
			final usuarioId = await AuthService.obtenerUsuarioId();
			if (usuarioId != null) {
				_clienteId = usuarioId;
				final vehiculos = await VehiculoService.obtenerPorCliente(usuarioId);
				setState(() {
					_vehicles = vehiculos;
				});
			}
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
				);
			}
		} finally {
			if (mounted) {
				setState(() => _isLoading = false);
			}
		}
	}

	Future<void> _addVehicle() async {
		final vehiculoCreado = await Navigator.of(context).push(
			MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
		);

		if (vehiculoCreado == true && mounted) {
			_cargarVehiculos();
		}
	}

	Future<void> _removeVehicle(dynamic vehicle) async {
		try {
			// Dialogo de confirmación
			final confirmar = await showDialog<bool>(
				context: context,
				builder: (ctx) => AlertDialog(
					title: const Text('Eliminar Vehículo'),
					content: const Text('¿Estás seguro de que deseas eliminar este vehículo de tu cuenta? Esta acción no se puede deshacer.'),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(ctx, false),
							child: const Text('Cancelar'),
						),
						TextButton(
							onPressed: () => Navigator.pop(ctx, true),
							child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
						),
					],
				),
			);

			if (confirmar != true) return;

			setState(() => _isLoading = true);
			await VehiculoService.delete(vehicle['_id'] ?? vehicle['id']);
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Vehículo eliminado exitosamente.')),
				);
				_cargarVehiculos();
			}
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
				);
				setState(() => _isLoading = false);
			}
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFFF2F5F6),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const Text(
								'Mis vehículos',
								style: TextStyle(
									color: Color(0xFF16262D),
									fontSize: 26,
									fontWeight: FontWeight.w700,
								),
							),
							const SizedBox(height: 6),
							const Text(
								'Administra los vehículos asociados a tu cuenta.',
								style: TextStyle(color: Color(0xFF5C6B73), fontSize: 14),
							),
							const SizedBox(height: 20),
							Expanded(
								child: _isLoading
										? const Center(child: CircularProgressIndicator(color: Color(0xFF12566B)))
										: _vehicles.isEmpty
												? _buildEmptyState()
												: ListView.separated(
														itemCount: _vehicles.length,
														separatorBuilder: (context, index) => const SizedBox(height: 12),
														itemBuilder: (context, index) => _buildVehicleCard(_vehicles[index]),
													),
							),
							SizedBox(
								width: double.infinity,
								child: ElevatedButton.icon(
									onPressed: _addVehicle,
									icon: const Icon(Icons.add_rounded),
									label: const Text('Agregar vehículo'),
									style: ElevatedButton.styleFrom(
										backgroundColor: const Color(0xFF12566B),
										foregroundColor: Colors.white,
										padding: const EdgeInsets.symmetric(vertical: 15),
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(14),
										),
									),
								),
							),
						],
					),
				),
			),
		);
	}

	Widget _buildEmptyState() {
		return Center(
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(
						Icons.directions_car_outlined,
						size: 64,
						color: const Color(0xFF12566B).withOpacity(0.45),
					),
					const SizedBox(height: 12),
					const Text(
						'Aún no tienes vehículos registrados',
						textAlign: TextAlign.center,
						style: TextStyle(
							color: Color(0xFF16262D),
							fontSize: 16,
							fontWeight: FontWeight.w600,
						),
					),
				],
			),
		);
	}

	Widget _buildVehicleCard(dynamic vehicle) {
		return Card(
			margin: EdgeInsets.zero,
			elevation: 1,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: InkWell(
				borderRadius: BorderRadius.circular(16),
				onTap: () => _showVehicleDetails(vehicle),
				child: ListTile(
				contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
				leading: const Icon(Icons.directions_car_outlined, color: Color(0xFF334A52), size: 34),
				title: Text(
					vehicle['marca'] ?? 'Marca desconocida',
					style: const TextStyle(fontWeight: FontWeight.w700),
				),
				subtitle: Text('${vehicle['placa'] ?? ''} · ${vehicle['color'] ?? ''} · ${vehicle['modelo'] ?? ''}'),
				trailing: IconButton(
					tooltip: 'Eliminar vehículo',
					onPressed: () => _removeVehicle(vehicle),
					icon: const Icon(Icons.delete_outline_rounded),
					color: const Color(0xFFE8821E),
				),
			),
		));
	}

	void _showVehicleDetails(dynamic vehicle) {
		showModalBottomSheet(
			context: context,
			isScrollControlled: true,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
			),
			builder: (ctx) {
				return Padding(
					padding: EdgeInsets.only(
						bottom: MediaQuery.of(ctx).viewInsets.bottom,
					),
					child: Container(
						padding: const EdgeInsets.all(24),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Row(
									mainAxisAlignment: MainAxisAlignment.spaceBetween,
									children: [
										const Text('Detalles del Vehículo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF16262D))),
										IconButton(
											onPressed: () => Navigator.pop(ctx),
											icon: const Icon(Icons.close),
										)
									]
								),
								const SizedBox(height: 16),
								_detailRow('Marca y Modelo', '${vehicle['marca'] ?? ''} ${vehicle['modelo'] ?? ''}'),
								_detailRow('Placa', vehicle['placa'] ?? ''),
								_detailRow('Año', vehicle['anio']?.toString() ?? ''),
								_detailRow('Color', vehicle['color'] ?? ''),
								_detailRow('Combustible', vehicle['tipoCombustible'] ?? ''),
								_detailRow('Chasis/VIN', vehicle['numeroChasis'] ?? ''),
								_detailRow('Aseguradora', vehicle['companiaAseguradora'] ?? ''),
								_detailRow('Estado Seguro', vehicle['estadoSeguro'] ?? ''),
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton.icon(
										onPressed: () {
											Navigator.pop(ctx);
											_editVehicle(vehicle);
										},
										icon: const Icon(Icons.edit_rounded),
										label: const Text('Editar vehículo'),
										style: ElevatedButton.styleFrom(
											backgroundColor: const Color(0xFFE8821E),
											foregroundColor: Colors.white,
											padding: const EdgeInsets.symmetric(vertical: 14),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
										),
									),
								)
							],
						),
					),
				);
			},
		);
	}

	Widget _detailRow(String label, String value) {
		return Padding(
			padding: const EdgeInsets.only(bottom: 12),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(label, style: const TextStyle(color: Color(0xFF5C6B73), fontSize: 14)),
					Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF16262D), fontSize: 14)),
				],
			),
		);
	}

	Future<void> _editVehicle(dynamic vehicle) async {
		final actualizado = await Navigator.of(context).push(
			MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicleToEdit: vehicle)),
		);
		if (actualizado == true && mounted) {
			_cargarVehiculos();
		}
	}
}