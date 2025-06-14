# IoTail Companion

Companion App for [IoTail](https://github.com/Pergo01/IoTail.git) IoT project

## Setup

1. Install Flutter from [here](https://flutter.dev/) if not present in your computer yet.
2. Install Flutter and Dart extension in your IDE.
3. Open the project with in your IDE.
4. Assuming a Firebase project is already available for IoTail, setup Firebase and Firebase CLI for this app by following [this](https://firebase.google.com/docs/flutter/setup?platform=android) tutorial (choose your own OS platform).
5. Assuming a ThingSpeak channel was already created for the IoT platform backend, create the file `settings.json` with the following structure and put it inside the assets directory:
    ```json
    {
        "channel_id": your_channel_ID_number,
        "thingspeak_read_api_key": "your_channel_read_api_key"
    }
    ```
6. From the app directory, either:
    - In the terminal, type `flutter pub get`
    - Open `pubspec.yaml` and press the button in the interface that says **Pub get**
7. Run the app from the play button.
8. To find the area of the shops on the map, go to this location (you can set it in the emulator or with a fake gps app): **44.88566825170957, 7.334846868977245**

Push Notification features are available on apple phisical devices only if the developer account is a paid account. In emulators, they work fine. Local notifications are ok everywhere, instead.

