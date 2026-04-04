//  final List<String> weatherOptions = [
//   // CLEAR
//   "CLEAR",
//   "CLEAR 0%", "CLEAR 5%", "CLEAR 10%", "CLEAR 15%", "CLEAR 20%",
//   "CLEAR 25%", "CLEAR 30%", "CLEAR 35%", "CLEAR 40%", "CLEAR 45%",
//   "CLEAR 50%", "CLEAR 55%", "CLEAR 60%", "CLEAR 65%", "CLEAR 70%",
//   "CLEAR 75%", "CLEAR 80%", "CLEAR 85%", "CLEAR 90%", "CLEAR 95%", "CLEAR 100%",

//   // SUNNY
//   "SUNNY",
//   "SUNNY 0%", "SUNNY 5%", "SUNNY 10%", "SUNNY 15%", "SUNNY 20%",
//   "SUNNY 25%", "SUNNY 30%", "SUNNY 35%", "SUNNY 40%", "SUNNY 45%",
//   "SUNNY 50%", "SUNNY 55%", "SUNNY 60%", "SUNNY 65%", "SUNNY 70%",
//   "SUNNY 75%", "SUNNY 80%", "SUNNY 85%", "SUNNY 90%", "SUNNY 95%", "SUNNY 100%",

//   // P'CLOUDY
//   "P'CLOUDY",
//   "P'CLOUDY 0%", "P'CLOUDY 5%", "P'CLOUDY 10%", "P'CLOUDY 15%", "P'CLOUDY 20%",
//   "P'CLOUDY 25%", "P'CLOUDY 30%", "P'CLOUDY 35%", "P'CLOUDY 40%", "P'CLOUDY 45%",
//   "P'CLOUDY 50%", "P'CLOUDY 55%", "P'CLOUDY 60%", "P'CLOUDY 65%", "P'CLOUDY 70%",
//   "P'CLOUDY 75%", "P'CLOUDY 80%", "P'CLOUDY 85%", "P'CLOUDY 90%", "P'CLOUDY 95%", "P'CLOUDY 100%",

//   // CLOUDY
//   "CLOUDY",
//   "CLOUDY 0%", "CLOUDY 5%", "CLOUDY 10%", "CLOUDY 15%", "CLOUDY 20%",
//   "CLOUDY 25%", "CLOUDY 30%", "CLOUDY 35%", "CLOUDY 40%", "CLOUDY 45%",
//   "CLOUDY 50%", "CLOUDY 55%", "CLOUDY 60%", "CLOUDY 65%", "CLOUDY 70%",
//   "CLOUDY 75%", "CLOUDY 80%", "CLOUDY 85%", "CLOUDY 90%", "CLOUDY 95%", "CLOUDY 100%",

//   // MIST
//   "MIST",
//   "MIST 0%", "MIST 5%", "MIST 10%", "MIST 15%", "MIST 20%",
//   "MIST 25%", "MIST 30%", "MIST 35%", "MIST 40%", "MIST 45%",
//   "MIST 50%", "MIST 55%", "MIST 60%", "MIST 65%", "MIST 70%",
//   "MIST 75%", "MIST 80%", "MIST 85%", "MIST 90%", "MIST 95%", "MIST 100%",

//   // FOG
//   "FOG",
//   "FOG 0%", "FOG 5%", "FOG 10%", "FOG 15%", "FOG 20%",
//   "FOG 25%", "FOG 30%", "FOG 35%", "FOG 40%", "FOG 45%",
//   "FOG 50%", "FOG 55%", "FOG 60%", "FOG 65%", "FOG 70%",
//   "FOG 75%", "FOG 80%", "FOG 85%", "FOG 90%", "FOG 95%", "FOG 100%",

//   // HAZY
//   "HAZY",
//   "HAZY 0%", "HAZY 5%", "HAZY 10%", "HAZY 15%", "HAZY 20%",
//   "HAZY 25%", "HAZY 30%", "HAZY 35%", "HAZY 40%", "HAZY 45%",
//   "HAZY 50%", "HAZY 55%", "HAZY 60%", "HAZY 65%", "HAZY 70%",
//   "HAZY 75%", "HAZY 80%", "HAZY 85%", "HAZY 90%", "HAZY 95%", "HAZY 100%",

//   // RAIN
//   "RAIN",
//   "RAIN 0%", "RAIN 5%", "RAIN 10%", "RAIN 15%", "RAIN 20%",
//   "RAIN 25%", "RAIN 30%", "RAIN 35%", "RAIN 40%", "RAIN 45%",
//   "RAIN 50%", "RAIN 55%", "RAIN 60%", "RAIN 65%", "RAIN 70%",
//   "RAIN 75%", "RAIN 80%", "RAIN 85%", "RAIN 90%", "RAIN 95%", "RAIN 100%",

//   // T-STORM
//   "T-STORM",
//   "T-STORM 0%", "T-STORM 5%", "T-STORM 10%", "T-STORM 15%", "T-STORM 20%",
//   "T-STORM 25%", "T-STORM 30%", "T-STORM 35%", "T-STORM 40%", "T-STORM 45%",
//   "T-STORM 50%", "T-STORM 55%", "T-STORM 60%", "T-STORM 65%", "T-STORM 70%",
//   "T-STORM 75%", "T-STORM 80%", "T-STORM 85%", "T-STORM 90%", "T-STORM 95%", "T-STORM 100%",

//   // DRIZZLE
//   "DRIZZLE",
//   "DRIZZLE 0%", "DRIZZLE 5%", "DRIZZLE 10%", "DRIZZLE 15%", "DRIZZLE 20%",
//   "DRIZZLE 25%", "DRIZZLE 30%", "DRIZZLE 35%", "DRIZZLE 40%", "DRIZZLE 45%",
//   "DRIZZLE 50%", "DRIZZLE 55%", "DRIZZLE 60%", "DRIZZLE 65%", "DRIZZLE 70%",
//   "DRIZZLE 75%", "DRIZZLE 80%", "DRIZZLE 85%", "DRIZZLE 90%", "DRIZZLE 95%", "DRIZZLE 100%",

//   // SHOWERS
//   "SHOWERS",
//   "SHOWERS 0%", "SHOWERS 5%", "SHOWERS 10%", "SHOWERS 15%", "SHOWERS 20%",
//   "SHOWERS 25%", "SHOWERS 30%", "SHOWERS 35%", "SHOWERS 40%", "SHOWERS 45%",
//   "SHOWERS 50%", "SHOWERS 55%", "SHOWERS 60%", "SHOWERS 65%", "SHOWERS 70%",
//   "SHOWERS 75%", "SHOWERS 80%", "SHOWERS 85%", "SHOWERS 90%", "SHOWERS 95%", "SHOWERS 100%",
//   ];