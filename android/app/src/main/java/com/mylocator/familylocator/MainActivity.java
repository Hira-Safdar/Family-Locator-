package com.mylocator.familylocator;

import android.content.Context;
import android.widget.TextView;

import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;

import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin;
import io.flutter.plugins.googlemobileads.NativeAdFactory;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine,
                "languageNative",
                new LanguageNativeAdFactory(this)
        );
    }

    @Override
    public void cleanUpFlutterEngine(FlutterEngine flutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "languageNative");
        super.cleanUpFlutterEngine(flutterEngine);
    }
}

final class LanguageNativeAdFactory implements NativeAdFactory {
    private final Context context;

    LanguageNativeAdFactory(Context context) {
        this.context = context;
    }

    @Override
    public NativeAdView createNativeAd(
            NativeAd nativeAd,
            Map<String, Object> customOptions
    ) {
        NativeAdView adView = new NativeAdView(context);
        TextView headline = new TextView(context);
        headline.setText(nativeAd.getHeadline());
        headline.setTextSize(16);
        headline.setPadding(24, 20, 24, 20);
        adView.setHeadlineView(headline);
        adView.addView(headline);
        adView.setNativeAd(nativeAd);
        return adView;
    }
}
