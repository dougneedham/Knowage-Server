/*
 * Knowage, Open Source Business Intelligence suite
 * Copyright (C) 2016 Engineering Ingegneria Informatica S.p.A.
 *
 * Knowage is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Knowage is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package it.eng.spagobi.tools.dataset.common.dataproxy;

import java.util.*;

import org.apache.commons.httpclient.HttpStatus;
import org.apache.commons.httpclient.NameValuePair;

import it.eng.spagobi.tools.dataset.common.datareader.IDataReader;
import it.eng.spagobi.tools.dataset.common.datastore.IDataStore;
import it.eng.spagobi.utilities.Helper;
import it.eng.spagobi.utilities.assertion.Assert;
import it.eng.spagobi.utilities.rest.RestUtilities;
import it.eng.spagobi.utilities.rest.RestUtilities.HttpMethod;
import it.eng.spagobi.utilities.rest.RestUtilities.Response;
import org.json.JSONArray;
import org.json.JSONObject;

/**
 * This data proxy makes REST calls. Providing all attributes (address, type of method, etc..) it make a http call and read the data store from the response
 * using the provided reader.
 *
 * @author fabrizio
 *
 */
public class RESTDataProxy extends AbstractDataProxy {

	private static final String NGSI_LIMIT = "1000";
	private static final int OFFSET_NOT_DEFINED = -1;
	private static final int FETCH_SIZE_NOT_DEFINED = -1;
	private static final int MAX_RESULT_NOT_DEFINED = -1;

	protected final String requestBody;
	protected String address;
	protected final Map<String, String> requestHeaders;
	protected final HttpMethod method;

	private final String offsetParam;
	private final String fetchSizeParam;
	private final String maxResultsParam;
	private final boolean ngsi;

	public RESTDataProxy(String address, HttpMethod method, String requestBody, Map<String, String> requestHeaders, String offsetParam, String fetchSizeParam,
			String maxResultsParam, boolean ngsi) {
		Helper.checkNotNull(address, "address");
		Helper.checkNotEmpty(address, "address");
		Helper.checkNotNull(method, "method");
		// cab be empty
		Helper.checkNotNull(requestHeaders, "requestHeaders");
		// can be null, can't empty
		if (requestBody != null) {
			Helper.checkNotEmpty(requestBody, "requestBody");
		}

		// offset and fetch size must exist together
		if (offsetParam != null) {
			Helper.checkNotEmpty(offsetParam, "offsetParam");
			Helper.checkNotNull(fetchSizeParam, "fetchSizeParam");
		}
		if (fetchSizeParam != null) {
			Helper.checkNotEmpty(fetchSizeParam, "fetchSizeParam");
			Helper.checkNotNull(offsetParam, "offsetParam");
		}
		if (maxResultsParam != null) {
			Helper.checkNotEmpty(maxResultsParam, "maxResultsParam");
		}

		this.address = address;
		this.method = method;
		this.requestBody = requestBody;
		this.requestHeaders = new HashMap<String, String>(requestHeaders);
		this.offsetParam = offsetParam;
		this.fetchSizeParam = fetchSizeParam;
		this.maxResultsParam = maxResultsParam;
		this.ngsi = ngsi;
		manageHeadersNGSI();
	}

	private void manageHeadersNGSI() {
		if (!ngsi) {
			return;
		}

		// add NGSI headers if they are not present
		String[][] ngsiHeaders = new String[][] { { "Accept", "application/json" } };
		for (String[] header : ngsiHeaders) {
			if (!requestHeaders.containsKey(header[0])) {
				requestHeaders.put(header[0], header[1]);
			}
		}
	}

	@Override
	public IDataStore load(IDataReader dataReader) {
		try {
			Helper.checkNotNull(dataReader, "dataReader");

			List<NameValuePair> query = getQuery();
			Response response = RestUtilities.makeRequest(this.method, setPaginationParameters(this.address, dataReader), this.requestHeaders, this.requestBody,
					query);
			String responseBody = response.getResponseBody();
			if (response.getStatusCode() != HttpStatus.SC_OK) {
				throw new RESTDataProxyException(
						String.format("The response status is not ok: status=%d, response=%s", response.getStatusCode(), responseBody));
			}
			Assert.assertNotNull(responseBody, "responseBody is null");
			dataReader.setCalculateResultNumberEnabled(calculateResultNumberOnLoad);

			JSONObject jsonObject = new JSONObject(responseBody);
			if(jsonObject.has("highlighting")){
				JSONObject highlighting = jsonObject.getJSONObject("highlighting");
				JSONObject jsonResponse = jsonObject.getJSONObject("response");
				JSONArray jsonDocs = jsonResponse.getJSONArray("docs");
				if(jsonDocs.length()>0){
					for (int i = 0; i < jsonDocs.length(); i++) {
						JSONObject jsonDoc = jsonDocs.getJSONObject(i);
						String id = jsonDoc.getString("id");
						JSONObject highlightingDetail = highlighting.getJSONObject(id);
						Iterator<String> keys = highlightingDetail.keys();
						while(keys.hasNext()){
							String field = keys.next();
							JSONArray jsonReplacement = highlightingDetail.getJSONArray(field);
							if(jsonReplacement.length()>0){
								String text = jsonReplacement.getString(0);
								jsonDoc.put(field, text);
							}
						}
					}
				}
				responseBody = jsonObject.toString();
			}

			IDataStore res = dataReader.read(responseBody);
			Assert.assertNotNull(res, "datastore is null");
			return res;
		} catch (RESTDataProxyException e) {
			throw e;
		} catch (Exception e) {
			throw new RESTDataProxyException(e);
		}
	}

	protected List<NameValuePair> getQuery() {
		List<NameValuePair> res = new ArrayList<NameValuePair>(3);
		if (offsetParam != null) {
			if (offset != OFFSET_NOT_DEFINED) {
				res.add(new NameValuePair(offsetParam, Integer.toString(offset)));
			}
			Assert.assertTrue(fetchSizeParam != null, "fetchSizeParam!=null");
			if (fetchSize != FETCH_SIZE_NOT_DEFINED) {
				res.add(new NameValuePair(fetchSizeParam, Integer.toString(fetchSize)));
			}
		}

		if (maxResultsParam != null && maxResults != MAX_RESULT_NOT_DEFINED) {
			res.add(new NameValuePair(maxResultsParam, Integer.toString(maxResults)));
		} else {
			if (ngsi) {
				res.add(new NameValuePair("limit", NGSI_LIMIT));
			}
		}

		return res;
	}

	protected String setPaginationParameters(String address, IDataReader dataReader) {
		return address;
	}

	public String getRequestBody() {
		return requestBody;
	}

	public String getAddress() {
		return address;
	}

	public Map<String, String> getRequestHeaders() {
		return requestHeaders;
	}

	public HttpMethod getRequestMethod() {
		return method;
	}

	@Override
	public boolean isOffsetSupported() {
		return offsetParam != null;
	}

	@Override
	public boolean isFetchSizeSupported() {
		return fetchSizeParam != null;
	}

	@Override
	public boolean isMaxResultsSupported() {
		return maxResultsParam != null;
	}

	@Override
	public boolean isPaginationSupported() {
		boolean res = offsetParam != null;
		Assert.assertTrue(res == (fetchSizeParam != null), "res==(fetchSizeParam!=null)");
		return res;
	}

	public String getOffsetParam() {
		return offsetParam;
	}

	public String getFetchSizeParam() {
		return fetchSizeParam;
	}

	public String getMaxResultsParam() {
		return maxResultsParam;
	}

}
