<%--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at
  
  http://www.apache.org/licenses/LICENSE-2.0
  
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
--%>
<%@ page 
  session="false"
  contentType="text/html; charset=UTF-8"
  pageEncoding="UTF-8"

  import="java.io.*"
  import="java.util.*"
  import="java.net.*"
  import="javax.servlet.http.*"
  import="javax.servlet.*"

  import="org.apache.nutch.html.Entities"
  import="org.apache.nutch.metadata.Nutch"
  import="org.apache.nutch.searcher.*"
  import="org.apache.nutch.plugin.*"
  import="org.apache.nutch.clustering.*"
  import="org.apache.hadoop.conf.*"
  import="org.apache.nutch.util.NutchConfiguration"
%><%!
  /**
   * Number of hits to retrieve and cluster if clustering extension is available
   * and clustering is on. By default, 100. Configurable via nutch-conf.xml.
   */
  private int HITS_TO_CLUSTER;

  /**
   * Maximum hits per page to be displayed.
   */
  private int MAX_HITS_PER_PAGE;

  /**
   * An instance of the clustering extension, if available.
   */
  private OnlineClusterer clusterer;
  
  /**
   * Nutch configuration for this servlet.
   */
  private Configuration nutchConf;

  /**
   * Initialize search bean.
   */
  public void jspInit() {
    super.jspInit();
    
    final ServletContext application = getServletContext(); 
    nutchConf = NutchConfiguration.get(application);
	  HITS_TO_CLUSTER = nutchConf.getInt("extension.clustering.hits-to-cluster", 100);
    MAX_HITS_PER_PAGE = nutchConf.getInt("searcher.max.hits.per.page", -1);

    try {
      clusterer = new OnlineClustererFactory(nutchConf).getOnlineClusterer();
    } catch (PluginRuntimeException e) {
      super.log("Could not initialize online clusterer: " + e.toString());
    }
  }
%>

<%--
// Uncomment this to enable query refinement.
// Do the same to "refine-query.jsp" below.,
<%@ include file="./refine-query-init.jsp" %>
--%>

<%
  // The Nutch bean instance is initialized through a ServletContextListener 
  // that is setup in the web.xml file
  NutchBean bean = NutchBean.get(application, nutchConf);
  // set the character encoding to use when interpreting request values 
  request.setCharacterEncoding("UTF-8");

  bean.LOG.info("query request from " + request.getRemoteAddr());

  // get query from request
  String queryString = request.getParameter("query");
  if (queryString == null)
    queryString = "";
  String htmlQueryString = Entities.encode(queryString);
  
  // a flag to make the code cleaner a bit.
  boolean clusteringAvailable = (clusterer != null);

  String clustering = "";
  if (clusteringAvailable && "yes".equals(request.getParameter("clustering")))
    clustering = "yes";

  int start = 0;          // first hit to display
  String startString = request.getParameter("start");
  if (startString != null)
    start = Integer.parseInt(startString);

  int hitsPerPage = 15;          // number of hits to display
  //String hitsString = request.getParameter("hitsPerPage");
  String hitsString = "15";
  if (hitsString != null)
    hitsPerPage = Integer.parseInt(hitsString);
  if(MAX_HITS_PER_PAGE > 0 && hitsPerPage > MAX_HITS_PER_PAGE)
    hitsPerPage = MAX_HITS_PER_PAGE;

  int hitsPerSite = 2;                            // max hits per site
  String hitsPerSiteString = request.getParameter("hitsPerSite");
  if (hitsPerSiteString != null)
    hitsPerSite = Integer.parseInt(hitsPerSiteString);

  String sort = request.getParameter("sort");
  boolean reverse =
    sort!=null && "true".equals(request.getParameter("reverse"));

  String params = "&hitsPerPage="+hitsPerPage
     +(sort==null ? "" : "&sort="+sort+(reverse?"&reverse=true":""));

  int hitsToCluster = HITS_TO_CLUSTER;            // number of hits to cluster

  // get the lang from request
  String queryLang = request.getParameter("lang");
  if (queryLang == null) { queryLang = ""; }
  Query query = Query.parse(queryString, queryLang, nutchConf);
  bean.LOG.info("query: " + queryString);
  bean.LOG.info("lang: " + queryLang);

  String language =
    ResourceBundle.getBundle("org.nutch.jsp.search", request.getLocale())
    .getLocale().getLanguage();
  String requestURI = HttpUtils.getRequestURL(request).toString();
  String base = requestURI.substring(0, requestURI.lastIndexOf('/'));
  String rss = "../opensearch?query="+htmlQueryString
    +"&hitsPerSite="+hitsPerSite+"&lang="+queryLang+params;
%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<%
  // To prevent the character encoding declared with 'contentType' page
  // directive from being overriden by JSTL (apache i18n), we freeze it
  // by flushing the output buffer. 
  // see http://java.sun.com/developer/technicalArticles/Intl/MultilingualJSP/
  out.flush();
%>
<%@ taglib uri="http://jakarta.apache.org/taglibs/i18n" prefix="i18n" %>
<i18n:bundle baseName="org.nutch.jsp.search"/>
<html lang="<%= language %>">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<head>
<title><%=htmlQueryString%> - 中国德安网为您服务！</title>
<link href="/css/ruichang.css" rel="stylesheet" type="text/css" />
<link rel="icon" href="img/favicon.ico" type="image/x-icon"/>
<link rel="shortcut icon" href="img/favicon.ico" type="image/x-icon"/>
<link rel="alternate" type="application/rss+xml" title="RSS" href="<%=rss%>"/>
<jsp:include page="include/style.html"/>
<base href="<%= base  + "/" + language %>/">
<script type="text/javascript">
<!--
function queryfocus() { document.search.query.focus(); }
// -->
</script>
<style type="text/css">
body{ margin:0 auto; font-size:12px; font-family:Arial, Helvetica, sans-serif; line-height:1.5; background:#CCC; }
ul,dl,dd,h1,h2,h3,h4,h5,h6,form,p{ padding:0; margin:0;}
h1,h2,h3,h4,h5,h6{ font-size:14px; }
ul{ list-style:none;}
img{ border:0px; margin: 0px; padding: 0px; }
a{ color:#555; text-decoration:none; }
a:hover{ color:#F00; text-decoration: underline; }
.clearfloat{clear:both; height:0; font-size:1px; line-height:0px; }
#container{ width:900px; border:#999 1px solid; background:#FFF; padding:20px; margin:0 auto; }
.bar{ height:35px; line-height:35px; border-bottom:1px dotted #999; }
.bar a{ color:#C00; }
.srh{ padding:10px; text-align:center; font-size:14px; }
.btn{ font-size:14px; }
.list ul{ border:#CCC 1px solid; padding:10px; background:#F0F0F0; }
.list ul li{ height:20px; line-height:20px; }
.tit{ font-size:14px; }
.tit a{ color:#C00; }
.yy{ text-indent:2em; }
.yy a{ color:#000; }
p{ height:40px; line-height:40px; padding-left:100px; }
p span{ padding:5px; }
</style>
</head>

<body onLoad="queryfocus();">
<!--顶部信息栏-->
<div id="header_inf">
    <ul>
        <li class="top_link">
            <a href="/">返回首页</a>
            <a href="/component/rss.html">RSS订制</a>
            <a href="javascript:void(0);" onClick="window.external.addFavorite('http://www.ruichang.gov.cn/','中国瑞昌网')">加入收藏</a>
            <a href="javascript:void(0);" onclick="this.style.behavior='url(#default#homepage)';this.setHomePage('http://www.ruichang.gov.cn/');">设为首页</a>
            <a href="/wangzhanweihu/guanyuwomen" target="_blank">关于我们</a>
<a href="/wangzhanweihu/wangzhandaohang" target="_blank">网站导航</a>
        </li>
    </ul>
</div>
<div id="container">
 <div class="bar"><a href="#">德安网首页</a>＞＞网站检索</div>
            <form name="searchform" method="get" action="/search/search.jsp" target="_blank">
                <input type="hidden" name="lang" value="zh"/>
                <input type="hidden" name="hitsPerSite" value="0"/>
                <input type="hidden" name="clustering" value=""/> 
 <div class="srh">标题：<input class="search_area" name="query" type="text" value="请输入关键字" onclick="this.value='';"/><input class="btn" name="" type="submit" value="检索" /><input name="" class="btn" type="button" value="高级检索" onclick="window.open('/component/online/advquery.do');"/></div>
</div>
<!--顶部信息栏结束-->
<div id="whole_bg">
  <div id="content">

<div align="center">
 <form name="search" action="../search.jsp" method="get">
 <input name="query" size=44 value="<%=htmlQueryString%>">
 <input type="hidden" name="hitsPerPage" value="<%=hitsPerPage%>">
 <input type="hidden" name="lang" value="<%=language%>">
 <input type="hidden" name="hitsPerSite" value="<%=hitsPerSite%>">
 <input type="hidden" name="clustering" value="<%=clustering%>">
 <input type="submit" value="<i18n:message key="search"/>">
 <% if (clusteringAvailable) { %>
   <input id="clustbox" type="checkbox" name="clustering" value="yes" <% if (clustering.equals("yes")) { %>CHECKED<% } %>>
    <label for="clustbox"><i18n:message key="clustering"/></label>
 <% } %>
 <!--<a href="help.html">help</a>-->
 </form>

<%--
// Uncomment this to enable query refinement.
// Do the same to "refine-query-init.jsp" above.
<%@ include file="./refine-query.jsp" %>
--%>

<%
   // how many hits to retrieve? if clustering is on and available,
   // take "hitsToCluster", otherwise just get hitsPerPage
   int hitsToRetrieve = (clusteringAvailable && clustering.equals("yes") ? hitsToCluster : hitsPerPage);

   if (clusteringAvailable && clustering.equals("yes")) {
     bean.LOG.info("Clustering is on, hits to retrieve: " + hitsToRetrieve);
   }

   // perform query
    // NOTE by Dawid Weiss:
    // The 'clustering' window actually moves with the start
    // position.... this is good, bad?... ugly?....
   Hits hits;
   try{
      query.getParams().initFrom(start + hitsToRetrieve, hitsPerSite, "site", sort, reverse);
     hits = bean.search(query);
   } catch (IOException e){
     hits = new Hits(0,new Hit[0]);	
   }
   int end = (int)Math.min(hits.getLength(), start + hitsPerPage);
   int length = end-start;
   int realEnd = (int)Math.min(hits.getLength(), start + hitsToRetrieve);

   Hit[] show = hits.getHits(start, realEnd-start);
   HitDetails[] details = bean.getDetails(show);
   Summary[] summaries = bean.getSummary(details, query);
   bean.LOG.info("total hits: " + hits.getTotal());
%>

<i18n:message key="hits">
  <i18n:messageArg value="<%=new Long((end==0)?0:(start+1))%>"/>
  <i18n:messageArg value="<%=new Long(end)%>"/>
  <i18n:messageArg value="<%=new Long(hits.getTotal())%>"/>
</i18n:message>

<%
// be responsive
out.flush();
%>
</div>
<br><br>
<div align="left" style="margin-left:20px;">

<% if (clustering.equals("yes") && length != 0) { %>
<table border=0 cellspacing="3" cellpadding="0">

<tr>

<td valign="top">

<% } %>

<%
  for (int i = 0; i < length; i++) {      // display the hits
    Hit hit = show[i];
    HitDetails detail = details[i];
    String title = detail.getValue("title");
    String url = detail.getValue("url");
    String id = "idx=" + hit.getIndexNo() + "&id=" + hit.getUniqueKey();
    String summary = summaries[i].toHtml(true);
    String caching = detail.getValue("cache");
    boolean showSummary = true;
    boolean showCached = true;
    if (caching != null) {
      showSummary = !caching.equals(Nutch.CACHING_FORBIDDEN_ALL);
      showCached = !caching.equals(Nutch.CACHING_FORBIDDEN_NONE);
    }

    if (title == null || title.equals("")) {      // use url for docs w/o title
      title = url;
    }
    %>
    <b><a href="<%=url%>" target="_blank"><%=Entities.encode(title)%></a></b>
    <%@ include file="more.jsp" %>
    <% if (!"".equals(summary) && showSummary) { %>
    <br><span style="font-size:10pt;"><%=summary%></span>
    <% } %>
    <br>
    <span class="url"><%=Entities.encode(url)%></span>
    <%
      if (showCached) {
        %>(<a href="../cached.jsp?<%=id%>"><i18n:message key="cached"/></a>) <%
    }
    %>
    <!--(<a href="../explain.jsp?<%=id%>&query=<%=URLEncoder.encode(queryString, "UTF-8")%>&lang=<%=queryLang%>"><i18n:message key="explain"/></a>)-->
    <!--(<a href="../anchors.jsp?<%=id%>"><i18n:message key="anchors"/></a>)-->
    <% if (hit.moreFromDupExcluded()) {
    String more =
    "query="+URLEncoder.encode("site:"+hit.getDedupValue()+" "+queryString, "UTF8")
    +params+"&hitsPerSite="+0
    +"&lang="+queryLang
    +"&clustering="+clustering;%>
    (<a href="../search.jsp?<%=more%>"><i18n:message key="moreFrom"/>
     <%=hit.getDedupValue()%></a>)
    <% } %>
    <br><br>
<% } %>

<% if (clustering.equals("yes") && length != 0) { %>

</td>

<!-- clusters -->
<td style="border-right: 1px dotted gray;" />&#160;</td>
<td align="left" valign="top" width="25%">
<%@ include file="cluster.jsp" %>
</td>

</tr>
</table>

<% } %>
</div>

<table align="center">
	<tr>
		  <td>
		  	<%
		  		if (start >= hitsPerPage){
		  	%>
		    <form name="prev" action="../search.jsp" method="get">
		    <input type="hidden" name="query" value="<%=htmlQueryString%>">
		    <input type="hidden" name="lang" value="<%=queryLang%>">
		    <input type="hidden" name="start" value="<%=start-hitsPerPage%>">
		    <input type="hidden" name="hitsPerPage" value="<%=hitsPerPage%>">
		    <input type="hidden" name="hitsPerSite" value="<%=hitsPerSite%>">
		    <input type="hidden" name="clustering" value="<%=clustering%>">
		    <input type="submit" value="上一页">
		  	</form>
		  	<%
		  	}
		  	%>
		  </td>
			<%
			int startnum = 1;
			if ((int)(start/hitsPerPage)>=5)
				startnum = (int)(start/hitsPerPage)-4;
			for(int i=hitsPerPage*(startnum-1),j=0;i<=hits.getTotal()&&j<=15;){
			%>
			<td>
		<form name="next" action="../search.jsp" method="get">
    <input type="hidden" name="query" value="<%=htmlQueryString%>">
    <input type="hidden" name="lang" value="<%=queryLang%>">
    <input type="hidden" name="start" value="<%=i%>">
    <input type="hidden" name="hitsPerPage" value="<%=hitsPerPage%>">
    <input type="hidden" name="hitsPerSite" value="<%=hitsPerSite%>">
    <input type="hidden" name="clustering" value="<%=clustering%>">
  	<a style="text-decoration:none;" href="../search.jsp?query=<%=URLEncoder.encode(queryString,"UTF-8")%>&lang=zh&start=<%=i%>&hitsPerPage=<%=hitsPerPage%>&hitsPerSite=<%=hitsPerSite%>&clustering="> <%=i/hitsPerPage+1%></a>&nbsp;
<% if (sort != null) { %>
    <input type="hidden" name="sort" value="<%=sort%>">
    <input type="hidden" name="reverse" value="<%=reverse%>">
<% } %>
    </form>
  </td>
    <%
    i=i+15;
    j++;
    }
    %>
		<td>
<%
if ((hits.totalIsExact() && end < hits.getTotal()) // more hits to show
    || (!hits.totalIsExact() && (hits.getLength() > start+hitsPerPage))) {
%>
    <form name="next" action="../search.jsp" method="get">
    <input type="hidden" name="query" value="<%=htmlQueryString%>">
    <input type="hidden" name="lang" value="<%=queryLang%>">
    <input type="hidden" name="start" value="<%=end%>">
    <input type="hidden" name="hitsPerPage" value="<%=hitsPerPage%>">
    <input type="hidden" name="hitsPerSite" value="<%=hitsPerSite%>">
    <input type="hidden" name="clustering" value="<%=clustering%>">
    <input type="submit" value="<i18n:message key="next"/>">
<% if (sort != null) { %>
    <input type="hidden" name="sort" value="<%=sort%>">
    <input type="hidden" name="reverse" value="<%=reverse%>">
<% } %>
    </form>
<%
    }
%>
</td>
</tr>
</table>

<center>
<p>
<a href="http://wiki.apache.org/nutch/FAQ">
<img border="0" src="../img/poweredbynutch_01.gif">
</a>
</center>
<!--<jsp:include page="/include/footer.html"/>-->
</div>
            <div id="footer">
    <div id="footer_content">
      <div class="footer_logo"></div>
      <div class="footer_linkbar">
        <p><a href="http://www.jjpolice.gov.cn/beian.php?id=20090708110605" target="_blank"><img src="/images/110.jpg" width="118" height="51" /></a></p>
        <p><a href="http://59.52.97.234:8104/index2.jsp" target="_blank"><img src="/images/jubao.jpg" width="117" height="50" /></a></p>
      </div>
      <div class="footer_inf">
        <p><ul>
          <li>
<a href="/wangzhanweihu/guanyuwomen" target="_blank">关于我们</a>
</li><li>|</li><li>
<a href="/wangzhanweihu/wangzhandaohang" target="_blank">网站导航</a>
</li><li>|</li><li>
<a href="/wangzhanweihu/banquanshuoming" target="_blank">版权说明</a>
</li><li>|</li><li>
<a href="/wangzhanweihu/yinsishengming" target="_blank">隐私声明</a>
</li></ul></p>
        <p>版权所有：瑞昌市人民政府 | 组织建设：瑞昌市人民政府 | 制作维护：瑞昌市人民政府信息化工作办公室</p>
        <p>电 话：0792-4224685  邮箱：rcgov@sina.com　ICP备案编号：赣ICP备05006010号</p>
        <p>建议：电脑显示屏的分辨率1024*以上768；IE浏览器6.0以上；FlashPlayer8.0以上</p>
      </div>
    </div></div>
</div></div>
</body>
</html>
