# By default, Faraday sorts the parameters in the request URL/body. This serves
# absolutely no purpose and actually breaks the API for Apple MapKit JS, which
# utilizes signed URLs for Snapshot requests.
Faraday::NestedParamsEncoder.sort_params = false
Faraday::FlatParamsEncoder.sort_params = false
