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

    // so, the idea here is that you can wrap your method in `safely` and it
    // will catch all exceptions and report them to a global error handling
    // module. this could do things like pop up an alert / report to crashlytics
    // etc
    safely(() async {
      try {
        final weather = await _weatherService.getWeather(city);
        emit(WeatherLoadSuccess(weather));
        // BUT, you can still try/catch here yourself to handle any errors you
        // specifically wanna deal with yourself. e.g. here we handle some
        // known exceptions, but we also wrap in "safely" so that for errors
        // we're not prepared to handle, we can rely on the global behavior
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
