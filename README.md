<p align="center">
  <img src="logo.jpg" height="250" /> <br /><br />
  <a href="https://apps.apple.com/ca/app/onepetri/id1576075754?uo=4">
    <img src="https://onepetri.ai/assets/appstore.png" height="70" />
  </a>
</p>


# OnePetri
### AI-Powered Petri Dish Analysis

Michael Shamash <br />
Maurice Lab <br />
McGill University <br />
michael@onepetri.ai

## Current Version
OnePetri v1.0.0-6 is the [latest public release](https://github.com/mshamash/OnePetri/releases)

## Citation
*Coming soon...*

---

## Table of Contents
1. [Changelog](#changelog)
2. [App Description](#about)
3. [Using OnePetri](#use)
4. [Contact](#contact)
5. [Copyright](#copyright)


---

## Changelog <a name="changelog"></a>
The full changelog for OnePetri (iOS) can be found [here](https://onepetri.ai/changelog/) or on the releases page [here](https://github.com/mshamash/OnePetri/releases).


## App Description <a name="about"></a>
Harness the power of AI and accelerate common microbiological petri dish assays with OnePetri!

Tired of manually counting plaques on petri dishes? Count plaques in near real-time with OnePetri, an automated plaque counting iOS app!

OnePetri currently supports bacteriophage plaque-based assays, with support for bacterial CFU counts coming in a future release!

### About OnePetri

OnePetri uses machine learning models & computer vision to automatically detect petri dishes and plaques, count plaques, and perform common assay calculations with these values (plaque/titration assay).

Note that as of now, OnePetri only works with circular petri dishes; however, other shapes (square & rectangle) may be added if sufficient training images can be obtained. Additionally, the models used in the app require one plate per dilution, and as such, spot assays are not currently supported.

All image processing & detection is done locally on-device, with no need for an internet connection once the app has been installed. As such, OnePetri does not collect, store, or transmit any user data or images. Updates are likely to be released regularly, so regular access to the internet is strongly recommended.

### Plaque count accuracy & validation

There are no restrictions on how OnePetri is used; however, the models included in the app may occasionally miscount plaques (too many, or too few) and this could affect downstream experiments and calculations. As such, all counts done by the app should always be validated by manual counting or another established "gold standard", especially in cases where it is critical to know precise values (ie. phage titration for phage therapy). The model accuracy will improve with each release thanks to additional training data provided by the community.

### Help make OnePetri even better!

OnePetri uses machine learning models to detect petri dishes and plaques (and soon bacterial colonies!). If you're interested in helping expand the training datasets to improve the models' performance, reach out by email to (support@onepetri.ai) . OnePetri is also completely open source, with the initial training dataset and app source code publicly available!

## Using OnePetri <a name="use"></a>
*Coming soon...*

## Contact <a name="contact"></a>
If you have any questions or comments on OnePetri, please contact Michael Shamash (michael@onepetri.ai) or [create a GitHub issue in this repository](https://github.com/mshamash/OnePetri/issues)!

## Copyright <a name="copyright"></a>
OnePetri - AI-Powered Petri Dish Analysis <br />
Copyright (C) 2021 Michael Shamash <br />
<br />
This program is free software: you can redistribute it and/or modify <br />
it under the terms of the GNU General Public License as published by <br />
the Free Software Foundation, either version 3 of the License, or <br />
(at your option) any later version. <br />
<br />
This program is distributed in the hope that it will be useful, <br />
but WITHOUT ANY WARRANTY; without even the implied warranty of <br />
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the <br />
GNU General Public License for more details. <br />
<br />
You should have received a copy of the GNU General Public License <br />
along with this program.  If not, see <https://www.gnu.org/licenses/>. <br />
