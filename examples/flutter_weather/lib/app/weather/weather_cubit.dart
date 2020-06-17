import 'package:cubit/cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_weather/service/service.dart';
import 'package:http/http.dart';

@immutable
abstract class WeatherState {}

class WeatherInitial extends WeatherState {}

class WeatherLoadInProgress extends WeatherState {}

class WeatherLoadSuccess extends WeatherState {
  WeatherLoadSuccess(this.weather);

  final Weather weather;
}

class WeatherLoadFailure extends WeatherState {}

class WeatherCubit extends SafeCubit<WeatherState> {
  WeatherCubit(this._weatherService) : super(initialState: WeatherInitial());

  final WeatherService _weatherService;

  Future<void> getWeather({@required String city}) async {
    if (city == null || city.isEmpty) return;

    emit(WeatherLoadInProgress());

    safely(() async {
      try {
        final weather = await _weatherService.getWeather(city);
        emit(WeatherLoadSuccess(weather));
      } on ClientException catch (_) {
        emit(WeatherLoadFailure());
      }
    });
  }
}

class SafeCubit<T> extends Cubit<T> {
  SafeCubit({
    @required T initialState,
    GlobalErrorHandling globalErrorHandling,
  })  : _globalErrorHandling =
            globalErrorHandling ?? GlobalErrorHandling.instance,
        super(initialState: initialState);

  final GlobalErrorHandling _globalErrorHandling;

  @protected
  void safely(VoidCallback action) {
    try {
      action();
    } on Exception catch (error) {
      _globalErrorHandling.apply(error);
    }
  }
}

class GlobalErrorHandling {
  GlobalErrorHandling._();

  static GlobalErrorHandling get instance => GlobalErrorHandling._();

  void apply(Exception exception) {}
}
