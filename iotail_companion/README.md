# IoTail Companion

Companion App for [IoTail](https://github.com/Pergo01/IoTail.git) IoT project.
⚠️ Setup the IoTail backend in that repository before working on this.

## Setup

1. Install Flutter from [here](https://flutter.dev/) if not present in your computer yet.
2. Install Flutter and Dart extension in your IDE.
3. Clone this repository
4. Open the project in your IDE.
5. Assuming a Firebase project is already available for IoTail, setup Firebase and Firebase CLI for this app by following [this](https://firebase.google.com/docs/flutter/setup?platform=android) tutorial (choose your own OS platform).
6. Assuming a [ThingSpeak](https://thingspeak.mathworks.com/) channel was already created for the IoT platform backend, note the channel number and the read API key (from the "API Keys" section)

6. Create the file `settings.json` with the following structure and put it inside the assets directory:
    ```json
    {
        "channel_id": 1234567,
        "thingspeak_read_api_key": "your_channel_read_api_key"
    }
    ```
7. From the app directory, either:
    - In the terminal, type `flutter pub get`
    - Open `pubspec.yaml` and press the button in the interface that says **Pub get**
8. Run the app from the play button.
9. To find the area of the shops on the map, go to this location (you can set it in the emulator or with a fake gps app): **44.88566825170957, 7.334846868977245**

Push Notification features are available on Apple phisical devices only if the developer account is a paid account. In emulators, they work fine. Local notifications are ok everywhere, instead.

## Mock users for testing

There are two mock users:
- John Doe
    - email: john.doe@gmail.com
    - password: 123456789

    User with one dog already present
- Johanna Doe
    - email: johanna.doe@gmail.com
    - password: 987654321

    Completely empty user

