const getLocation = () => {
  const x = document.querySelector("#demo")
  const getLocation = document.getElementById("getlocation"); getLocation.addEventListener("click", (event) => {
     if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(showPosition);
    } else {
      x.innerHTML = "Geolocation is not supported by this browser.";
      console.log("Fail")
    }
     });

  const showPosition = (position) => {
  x.innerHTML = position.coords.latitude +
  ", " + position.coords.longitude;
  console.log("Succeed")
  }
}



export { getLocation };
