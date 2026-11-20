# Rwanda Food Price Prediction

## 1. Mission and problem

- **Mission:** Support food security in Rwanda by helping farmers, traders and NGOs make better-informed decisions about food prices.
- **Problem:** Food prices vary by market, item and year, so it is hard to know whether a price is fair, or when and where to buy or sell.
- **Solution:** A regression model trained on WFP market price data predicts the retail price per kilogram of a food item in a Rwandan market and month.
- **Access:** The model is served by a FastAPI service on Render and used from a one-page Flutter mobile app.

## 2. Dataset

**WFP Food Prices for Rwanda**, published by the World Food Programme on the Humanitarian Data Exchange (HDX): https://data.humdata.org/dataset/wfp-food-prices-for-rwanda

The file has 157,793 rows (January 2000 to August 2026) and 16 columns: region, district, market, coordinates, commodity category, commodity, unit, price type, date and price. The target is `price`, a continuous number in Rwandan francs (RWF). I kept only prices per kilogram (138,578 rows after cleaning) and used five inputs: market, commodity, price type, year and month.

## 3. Public API (Swagger UI)

https://rwanda-food-price-api.onrender.com/docs

The API is hosted on Render's free plan, so it sleeps after 15 minutes without traffic. The first request can take up to a minute while it wakes up.

## 4. Video demo

https://youtu.be/gmUQGSVW328

## 5. How to run the mobile app

The app runs on an Android emulator or a phone (not as a web app) and calls the public API above, so no local server is needed.

**You need:** [Flutter](https://docs.flutter.dev/get-started/install) (check with `flutter doctor`) and either an Android emulator (created in Android Studio's Device Manager) or an Android phone with USB debugging turned on.

1. Clone the repository and open the app folder:

   ```bash
   git clone https://github.com/KennyGael/Summative_ML.git
   cd Summative_ML/summative/FlutterApp
   ```

2. Install the packages:

   ```bash
   flutter pub get
   ```

3. Start an Android emulator (or plug in your phone):

   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

4. Check that Flutter sees the device:

   ```bash
   flutter devices
   ```

5. Open the Swagger link above in a browser to wake the API, then run the app and choose the emulator or phone (not Chrome):

   ```bash
   flutter run
   ```

6. Use the app: enter values in the five fields, for example Market `Kigali`, Commodity `Maize`, Price type `Retail`, Year `2025`, Month `6`, and press **Predict**. The predicted price per kilogram appears in the display area. A missing value, a wrong type or an out-of-range value (such as month `13`) shows a readable error message in the same area.

The API address is set in `summative/FlutterApp/lib/api_service.dart` (line 8).
