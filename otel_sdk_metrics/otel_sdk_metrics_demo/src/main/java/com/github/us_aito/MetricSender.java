package com.github.us_aito;

import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.metrics.DoubleHistogram;
import io.opentelemetry.api.metrics.LongCounter;
import io.opentelemetry.api.metrics.Meter;
import io.opentelemetry.exporter.otlp.metrics.OtlpGrpcMetricExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.metrics.SdkMeterProvider;
import io.opentelemetry.sdk.metrics.export.PeriodicMetricReader;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.semconv.resource.attributes.ResourceAttributes;

import java.time.Duration;
import java.util.Random;

public class MetricSender {

    public static void main(String[] args) throws InterruptedException {
        // 1. SDKの初期化（ここがAgentの代わりとなる設定部分）
        // ---------------------------------------------------
        
        // リソース定義（サービス名など）
        Resource resource = Resource.getDefault().toBuilder()
                .put(ResourceAttributes.SERVICE_NAME, "my-java-service")
                .build();

        // エクスポーター設定（OTel Collectorなどが待ち受けるエンドポイント）
        OtlpGrpcMetricExporter exporter = OtlpGrpcMetricExporter.builder()
                .setEndpoint("http://localhost:4317") 
                .build();

        // MetricReader設定（一定間隔でExporterにプッシュする設定）
        PeriodicMetricReader reader = PeriodicMetricReader.builder(exporter)
                .setInterval(Duration.ofSeconds(5)) // テスト用に5秒間隔（本番は通常60秒など）
                .build();

        // MeterProvider設定
        SdkMeterProvider meterProvider = SdkMeterProvider.builder()
                .setResource(resource)
                .registerMetricReader(reader)
                .build();

        // OpenTelemetryインスタンスの作成
        OpenTelemetry openTelemetry = OpenTelemetrySdk.builder()
                .setMeterProvider(meterProvider)
                .buildAndRegisterGlobal();

        // 2. Meterの取得
        // ---------------------------------------------------
        // 計測器の名前を指定（通常はパッケージ名やクラス名）
        Meter meter = openTelemetry.getMeter("com.example.MetricSender");


        // 3. Instrument（測定項目）の定義
        // ---------------------------------------------------
        
        // Counter: 累積値を記録（例：リクエスト数）
        LongCounter requestCounter = meter.counterBuilder("app.request.count")
                .setDescription("Counts the number of requests")
                .setUnit("1")
                .build();

        // Histogram: 分布を記録（例：処理時間）
        DoubleHistogram processingDuration = meter.histogramBuilder("app.processing.duration")
                .setDescription("Processing duration in milliseconds")
                .setUnit("ms")
                .build();

        // Gauge (Observable): 現在の値をコールバックで取得（例：スレッドプール使用率、メモリ量など）
        meter.gaugeBuilder("app.memory.usage")
                .setDescription("Current memory usage")
                .setUnit("bytes")
                .buildWithCallback(measurement -> {
                    // コールバック内で現在の値を測定して記録
                    measurement.record(Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory());
                });


        // 4. メトリクスの記録（アプリケーションロジック内で実行）
        // ---------------------------------------------------
        System.out.println("Start sending metrics...");
        Random random = new Random();

        for (int i = 0; i < 10; i++) {
            // 属性（タグ）の定義
            Attributes attributes = Attributes.of(
                    AttributeKey.stringKey("method"), "GET",
                    AttributeKey.stringKey("endpoint"), "/api/data"
            );

            // カウンターをインクリメント
            requestCounter.add(1, attributes);

            // ヒストグラムに値を記録
            double latency = 100 + random.nextDouble() * 50;
            processingDuration.record(latency, attributes);

            System.out.println("Recorded metric: " + (i + 1));
            Thread.sleep(1000); 
        }

        // プロセス終了前にバッファにあるデータをフラッシュする
        meterProvider.shutdown().join(10, java.util.concurrent.TimeUnit.SECONDS);
    }
}