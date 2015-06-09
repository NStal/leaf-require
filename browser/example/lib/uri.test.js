

/**
 * Implementation of base URI resolving algorithm in rfc2396.
 * - Algorithm from section 5.2
 *   (ignoring difference between undefined and '')
 * - Regular expression from appendix B
 * - Tests from appendix C
 *
 * @param {string} uri the relative URI to resolve
 * @param {string} baseuri the base URI (must be absolute) to resolve against
 */
URI = function(){
    function resolveUri(sUri, sBaseUri) {
	if (sUri == '' || sUri.charAt(0) == '#') return sUri;
	var hUri = getUriComponents(sUri);
	if (hUri.scheme) return sUri;
	var hBaseUri = getUriComponents(sBaseUri);
	hUri.scheme = hBaseUri.scheme;
	if (!hUri.authority) {
	    hUri.authority = hBaseUri.authority;
	    if (hUri.path.charAt(0) != '/') {
		aUriSegments = hUri.path.split('/');
		aBaseUriSegments = hBaseUri.path.split('/');
		aBaseUriSegments.pop();
		var iBaseUriStart = aBaseUriSegments[0] == '' ? 1 : 0;
		for (var i in aUriSegments) {
		    if (aUriSegments[i] == '..')
			if (aBaseUriSegments.length > iBaseUriStart) aBaseUriSegments.pop();
		    else { aBaseUriSegments.push(aUriSegments[i]); iBaseUriStart++; }
		    else if (aUriSegments[i] != '.') aBaseUriSegments.push(aUriSegments[i]);
		}
		if (aUriSegments[i] == '..' || aUriSegments[i] == '.') aBaseUriSegments.push('');
		hUri.path = aBaseUriSegments.join('/');
	    }
	}
	var result = '';
	if (hUri.scheme   ) result += hUri.scheme + ':';
	if (hUri.authority) result += '//' + hUri.authority;
	if (hUri.path     ) result += hUri.path;
	if (hUri.query    ) result += '?' + hUri.query;
	if (hUri.fragment ) result += '#' + hUri.fragment;
	return result;
    }
    uriregexp = new RegExp('^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?');
    function getUriComponents(uri) {
	var c = uri.match(uriregexp);
	return { scheme: c[2], authority: c[4], path: c[5], query: c[7], fragment: c[9] };
    }
    var URI = {}
    URI.resolve = function(base,target){
        return resolveUri(target,base);
    }
    URI.normalize = function(url){
        return URI.resolve("",url);
    }
    return {URI:URI}
}()
