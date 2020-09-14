


const x = document.querySelector("#location")

const getLocation = () => {

  const getLocation = document.getElementById("getlocation"); getLocation.addEventListener("click", (event) => {

  console.log(event);
  console.log(event.currentTarget); });

  const placesInput = document.querySelector("#location")
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(showPosition);
  } else {
    x.innerHTML = "Geolocation is not supported by this browser.";
  }
}

const showPosition = (position) => {
  x.innerHTML = "Latitude: " + position.coords.latitude +
  "<br>Longitude: " + position.coords.longitude;
}

export { getLocation };
