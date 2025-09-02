# HydroPing iOS App (_PRIVATE PROJECT_)

> _NOTE: This repo is not meant for public use and is only made available publicly for job acquisition purposes only._

**Project Overview**
---
- LOC: 4,636<sup>*</sup>
- Team: 1
- Timeline: 2mo
- Language: Swift
- Main Packages: Google Firebase

<sup>*</sup>Count excludes contents of .gitignore and other irrelevant files and directories.

**What's HydroPing**
---
The HydroPing system is an end-to-end solution that integrates custom embedded hardware, mobile applications, and a cloud backend to deliver reliable soil moisture monitoring and analytics. At its core, the STM32 microcontroller runs optimized firmware that manages power-efficient sensor sampling, data preprocessing, and wireless communication. The iOS app pairs with the device by activating Access Point (AP) Mode, providing users with real-time readings, local persistence, and a responsive dashboard for visualization. On the backend, a serverless architecture built with AWS Lambda and API Gateway securely ingests sensor data, performs time-series analysis, and exposes RESTful endpoints for app synchronization. The system design emphasizes modularity: the firmware ensures low-power continuous operation, the app handles user experience and offline caching, and the backend manages scalability and cross-device access. Together, these layers form a tightly integrated pipeline from hardware sensing to cloud intelligence, giving users actionable insights through a seamless and efficient interface.


**What's HydroPing APP**
---
HydroPing’s iOS application is built with a focus on reliability, minimal resource usage, and seamless user interaction. The app provides real-time soil moisture insights by pairing directly with HydroPing’s hardware sensor via the cloud. It leverages native iOS frameworks such as Wi-Fi Access Point for device communication, Core Data for lightweight local persistence, and SwiftUI/UIKit for an adaptive and responsive user interface. Data synchronization with the cloud is handled through a serverless API backend, ensuring secure and low-latency updates across devices. The architecture follows an MVVM (Model–View–ViewModel) pattern, simplifying state management and improving code modularity for long-term maintainability. Special attention was given to battery efficiency, offline caching, and error recovery, so the app continues functioning smoothly in varied network conditions and edge cases. Overall, the iOS app acts as a critical bridge between HydroPing’s physical device and its analytics platform, delivering a polished and intuitive user experience.


**Download the App**
---
The app is in final stages of receiving approval from the App Store and is currently being testing internally. 
