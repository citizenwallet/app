import 'dart:io';

import 'package:mocktail/mocktail.dart';

class MockHttpOverrides extends HttpOverrides {
  MockHttpOverrides(this.data);

  final Map<Uri, List<int>> data;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();
    final request = MockHttpClientRequest();
    final response = MockHttpClientResponse(data);
    final headers = MockHttpHeaders();

    /// Comment the exception when stub is missing from client
    /// because it complains about missing autoUncompress stub
    /// even setting it up as shown bellow.
    // throwOnMissingStub(client);
    throwOnMissingStub(request);
    throwOnMissingStub(response);
    throwOnMissingStub(headers);

    // This line is not necessary, it can be omitted.
    when(() => client.autoUncompress).thenReturn(true);

    // Use decompressed, otherwise you will get bad data.
    when(() => response.compressionState)
        .thenReturn(HttpClientResponseCompressionState.decompressed);

    // Capture the url and assigns it to requestedUrl from MockHttpClientResponse.
    when(() => client.getUrl(captureAny())).thenAnswer((invocation) {
      response.requestedUrl = invocation.positionalArguments[0] as Uri;
      return Future<HttpClientRequest>.value(request);
    });

    // This line is not necessary, it can be omitted.
    when(() => request.headers).thenAnswer((_) => headers);

    when(() => request.close())
        .thenAnswer((_) => Future<HttpClientResponse>.value(response));

    when(() => response.contentLength)
        .thenAnswer((_) => data[response.requestedUrl]!.length);

    when(() => response.statusCode).thenReturn(HttpStatus.ok);

    when(
      () => response.listen(
        captureAny(),
        cancelOnError: captureAny(named: 'cancelOnError'),
        onDone: captureAny(named: 'onDone'),
        onError: captureAny(named: 'onError'),
      ),
    ).thenAnswer((invocation) {
      final onData =
          invocation.positionalArguments[0] as void Function(List<int>);

      final onDone = invocation.namedArguments[#onDone] as void Function();

      final onError = invocation.namedArguments[#onError] as void
          Function(Object, [StackTrace]);

      final cancelOnError = invocation.namedArguments[#cancelOnError] as bool;

      return Stream<List<int>>.fromIterable([data[response.requestedUrl]!])
          .listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );
    });

    return client;
  }
}

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {
  MockHttpClientResponse(this.data);
  final Map<Uri, List<int>> data;
  Uri? requestedUrl;

  // It is not necessary to override this method to pass the test.
  @override
  Future<S> fold<S>(
    S initialValue,
    S Function(S previous, List<int> element) combine,
  ) {
    return Stream.fromIterable([data[requestedUrl]])
        .fold(initialValue, combine as S Function(S, List<int>?));
  }
}

class MockHttpHeaders extends Mock implements HttpHeaders {}
