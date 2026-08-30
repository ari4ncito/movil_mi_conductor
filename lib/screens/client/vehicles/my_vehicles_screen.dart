import 'package:flutter/material.dart';

import '/models/vehicle.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
	const MyVehiclesScreen({super.key});

	@override
	State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
	final List<Vehicle> _vehicles = [];

	Future<void> _addVehicle() async {
		final vehicle = await Navigator.of(context).push<Vehicle>(
			MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
		);

		if (vehicle != null && mounted) {
			setState(() => _vehicles.add(vehicle));
		}
	}

	void _removeVehicle(Vehicle vehicle) {
		setState(() => _vehicles.removeWhere((item) => item.id == vehicle.id));
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
								child: _vehicles.isEmpty
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
						color: const Color(0xFF12566B).withValues(alpha: 0.45),
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

	Widget _buildVehicleCard(Vehicle vehicle) {
		return Card(
			margin: EdgeInsets.zero,
			elevation: 1,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			child: ListTile(
				contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
				leading: Icon(vehicle.icon, color: vehicle.iconColor, size: 34),
				title: Text(
					vehicle.brand,
					style: const TextStyle(fontWeight: FontWeight.w700),
				),
				subtitle: Text('${vehicle.plates} · ${vehicle.color} · ${vehicle.year}'),
				trailing: IconButton(
					tooltip: 'Eliminar vehículo',
					onPressed: () => _removeVehicle(vehicle),
					icon: const Icon(Icons.delete_outline_rounded),
					color: const Color(0xFFE8821E),
				),
			),
		);
	}
}