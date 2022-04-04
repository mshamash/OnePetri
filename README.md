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
OnePetri v1.1.1-11 is the [latest public release](https://github.com/mshamash/OnePetri/releases)

## Citation
Please consider citing our [article in the journal PHAGE](https://doi.org/10.1089/phage.2021.0012) if you found OnePetri useful:

Shamash, M. & Maurice, C. F. OnePetri: Accelerating Common Bacteriophage Petri Dish Assays with Computer Vision. PHAGE: Therapy, Applications, and Research 2(4), 224-231 (2021).

---

## Table of Contents
1. [Changelog](#changelog)
2. [App Description](#about)
3. [Using OnePetri](#use)
4. [Benchmark Dataset & Results](#benchmark)
5. [Trained Models](#models)
6. [Contact](#contact)
7. [Copyright](#copyright)


---

## Changelog <a name="changelog"></a>
The full changelog for OnePetri (iOS) can be found [here](https://onepetri.ai/changelog/) or on the releases page [here](https://github.com/mshamash/OnePetri/releases).


## App Description <a name="about"></a>
Harness the power of AI and accelerate common microbiological Petri dish assays with OnePetri!

Tired of manually counting plaques on Petri dishes? Count plaques in near real-time with OnePetri, an automated plaque counting iOS app!

OnePetri currently supports bacteriophage plaque-based assays, with support for bacterial CFU counts coming in a future release!

### About OnePetri

OnePetri uses machine learning models & computer vision to automatically detect Petri dishes and plaques, count plaques, and perform common assay calculations with these values (plaque/titration assay).

Note that as of now, OnePetri only works with circular Petri dishes; however, other shapes (square & rectangle) may be added if sufficient training images can be obtained. Additionally, the models used in the app require one plate per dilution, and as such, spot assays are not currently supported.

All image processing & detection is done locally on-device, with no need for an internet connection once the app has been installed. As such, OnePetri does not collect, store, or transmit any user data or images. Updates are likely to be released regularly, so regular access to the internet is strongly recommended.

### Plaque count accuracy & validation

There are no restrictions on how OnePetri is used; however, the models included in the app may occasionally miscount plaques (too many, or too few) and this could affect downstream experiments and calculations. As such, all counts done by the app should always be validated by manual counting or another established "gold standard", especially in cases where it is critical to know precise values (ie. phage titration for phage therapy). The model accuracy will improve with each release thanks to additional training data provided by the community.

### Help make OnePetri even better!

OnePetri uses machine learning models to detect Petri dishes and plaques (and soon bacterial colonies!). If you're interested in helping expand the training datasets to improve the models' performance, reach out by email to (support@onepetri.ai) . OnePetri is also completely open source, with the initial training dataset and app source code publicly available!

## Using OnePetri <a name="use"></a>

### Quick count

Using the quick count feature, you can quickly get plaque counts for any image from your photo library or taken with your camera! Select the photo library or camera button to choose a photo from your library or take one with your camera, respectively. Then, Petri dishes will be detected. Tap the Petri dish of interest to proceed with analysis on that plate specifically. Finally, plaques will be detected and a final count will be returned. Don't blink or you'll miss it!

### Plaque assay

Choose the plaque assay option from the main menu. Using the stepper control, tap the + until reaching the number of plates/dilutions you would like to process. A maximum of 15 plates can be analyzed at any given moment. Select the plate you would like to analyze first and choose an image or take a photo for analysis. Once plaques are counted, the plate will be added to the plaque assay and PFU/mL calculated based on the value entered in the 'volume plated (uL)' field. The final averaged titre over all plates is shown at the bottom of the screen.

**Note**: plate 1 corresponds to tenfold dilution factor 10^-1, plate 2 corresponds to 10^-2, and so on...

**Note 2**: if you do not have all sequential plates in a dilution series, you may leave those plates blank and they will not be included in the final calculations.

*More assays coming soon...*

## Benchmark Dataset & Results <a name="benchmark"></a>
The benchmark dataset of 100 images and corresponding results can be found here https://github.com/mshamash/onepetri-benchmark.

## Trained Models <a name="models"></a>
The trained YOLOv5 models used within OnePetri can be found here https://github.com/mshamash/onepetri-models. The repository contains the PyTorch weights file (.pt extension) as well as the converted Apple CoreML model file (.mlmodel extension) and will be updated regularly, as new versions of the models are released.

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
