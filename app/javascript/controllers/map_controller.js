import { Controller } from "@hotwired/stimulus"
// import "leaflet"
// import "leaflet-css"
// import { DrawAreaSelection } from '@bopen/leaflet-area-selection';

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
          document.getElementById('ticket_geom').value = JSON.stringify(polygon.toGeoJSON(3).geometry, undefined, 2);
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
  }

  disconnect(){
    // this.map.remove()
  }
}
