//I used this Javascript Code to match the longitudes and latitudes in the UFO Sightings folder to US Counties, in order to create another column of data
//Originally the data only consisted of country, state, and city, but I was very interested in county data as well
//This uses the Google Maps API to match coordinates with county boundaries

function getCounty(lat, lng) {
   var apiKey = 'Insert Your API Key';
   var apiUrl = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' + lat + ',' + lng + '&key=' + apiKey;

   var response = UrlFetchApp.fetch(apiUrl);
   var data = JSON.parse(response.getContentText());

   Logger.log(data); //Log the entire API response to Apps Script logs

   for (var i = 0; i < data.results.length; i++) {
      var addressComponents = data.results[i].address_components;
      for (var j = 0; j < addressComponents.length; j++) {
         var types = addressComponents[j].types;
         if (types.includes('administrative_area_level_2')) {
            return addressComponents[j].long_name;
         }
      }
   }

   return 'County not found';
}
      
