import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/product.dart';
import '../../services/product_service.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc(this._service) : super(ProductInitial()) {
    on<LoadProducts>(_onLoad);
    on<SaveProduct>(_onSave);
    on<RefreshProducts>((_, _) => add(LoadProducts(query: _query)));
    on<DeleteProduct>(_onDelete);
  }

  final ProductService _service;
  String _query = '';

  Future<void> _onLoad(LoadProducts event, Emitter<ProductState> emit) async {
    _query = event.query;
    emit(ProductLoading());
    try {
      final products = await _service.getProducts(searchTerm: event.query);
      // Drop results of a search that has since been superseded.
      if (event.query != _query) return;
      emit(ProductLoaded(products, query: event.query));
    } catch (e) {
      if (event.query != _query) return;
      emit(ProductError('Gagal memuat produk: $e'));
    }
  }

  Future<void> _onSave(SaveProduct event, Emitter<ProductState> emit) async {
    emit(ProductSaving());
    try {
      var product = event.product;
      if (event.imageFilePath != null) {
        final path = await _service.uploadProductImage(event.imageFilePath!);
        product = product.copyWith(imagePath: path);
      }
      final isNew = product.id.isEmpty;
      if (isNew) {
        await _service.addProduct(product);
      } else {
        await _service.updateProduct(product);
      }
      emit(
        ProductOperationSuccess(
          isNew ? 'Produk ditambahkan.' : 'Produk diperbarui.',
        ),
      );
      add(LoadProducts(query: _query));
    } catch (e) {
      emit(ProductOperationFailure('Gagal menyimpan produk: $e'));
    }
  }

  Future<void> _onDelete(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductSaving());
    try {
      await _service.deleteProduct(event.id);
      emit(const ProductOperationSuccess('Produk dihapus.'));
      add(LoadProducts(query: _query));
    } catch (e) {
      emit(ProductOperationFailure('Gagal menghapus produk: $e'));
    }
  }
}
