import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="map"
export default class extends Controller {
  connect(){
    var map = L.map('map').setView([46, -94], 6);

    var tiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(map);

    var areaSelection = new window.leafletAreaSelection.DrawAreaSelection(
      {
        onPolygonReady: (polygon) => {
          document.getElementById('owner_service_area').value = JSON.stringify(polygon.toGeoJSON(3).geometry, undefined, 2);
        },
        onPolygonDblClick: (polygon, control, ev) => {
          const geojson = geoJSON(polygon.toGeoJSON(), {
            style: {
              opacity: 0.5,
              fillOpacity: 0.2,
              color: 'red',
            },
          });
          geojson.addTo(map);
          control.deactivate();
        },
        onButtonActivate: () => {
          const preview = document.getElementById('polygon');
          preview.textContent = 'Please draw your polygon';
        },
        onButtonDeactivate: (polygon) => {
          // console.log('Deactivated');
        },
        position: 'topleft',
        active: false
      }
    );

    map.addControl(areaSelection);

    if (document.getElementById('owner_service_area').value) {
      var geojsonFeature = JSON.parse(document.getElementById('owner_service_area').value)
      var geolayer = L.geoJSON(geojsonFeature).addTo(map);
      geolayer.eachLayer(function (layer) {
        map.fitBounds(layer.getBounds());
      });

    }
  }

  disconnect(){
    // this.map.remove()
  }
}
