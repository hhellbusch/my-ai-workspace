Source: https://cloud.google.com/compute/docs/gpus
Date: 2026-05-13
============================================================










<!doctype html>
<html 
      lang="en"
      dir="ltr">
  <head>
    <meta name="google-signin-client-id" content="721724668570-nbkv1cfusk7kk4eni4pjvepaus73b13t.apps.googleusercontent.com"><meta name="google-signin-scope"
          content="profile email https://www.googleapis.com/auth/developerprofiles https://www.googleapis.com/auth/developerprofiles.award https://www.googleapis.com/auth/devprofiles.full_control.firstparty"><meta property="og:site_name" content="Google Cloud Documentation">
    <meta property="og:type" content="website"><meta name="theme-color" content="#1a73e8"><meta charset="utf-8">
    <meta content="IE=Edge" http-equiv="X-UA-Compatible">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    

    <link rel="manifest" href="/_pwa/clouddocs/manifest.json"
          crossorigin="use-credentials">
    <link rel="preconnect" href="//www.gstatic.com" crossorigin>
    <link rel="preconnect" href="//fonts.googleapis.com" crossorigin>
    <link rel="preconnect" href="//www.google-analytics.com" crossorigin><link rel="stylesheet" href="//fonts.googleapis.com/css?family=Google+Sans:400,500|Roboto:400,400italic,500,500italic,700,700italic|Roboto+Mono:400,500,700&display=swap">
      <link rel="stylesheet"
            href="//fonts.googleapis.com/css2?family=Material+Icons&family=Material+Symbols+Outlined&display=block"><link rel="stylesheet" href="https://www.gstatic.com/devrel-devsite/prod/vb08cbdb02acf7f66ad9727ddfba9d81df8806422eb5dd63dba194c9c8c7997f7/clouddocs/css/app.css">
      
        <link rel="stylesheet" href="https://www.gstatic.com/devrel-devsite/prod/vb08cbdb02acf7f66ad9727ddfba9d81df8806422eb5dd63dba194c9c8c7997f7/clouddocs/css/dark-theme.css" disabled>
      <link rel="shortcut icon" href="https://www.gstatic.com/devrel-devsite/prod/vb08cbdb02acf7f66ad9727ddfba9d81df8806422eb5dd63dba194c9c8c7997f7/clouddocs/images/favicons/onecloud/favicon.ico">
    <link rel="apple-touch-icon" href="https://www.gstatic.com/devrel-devsite/prod/vb08cbdb02acf7f66ad9727ddfba9d81df8806422eb5dd63dba194c9c8c7997f7/clouddocs/images/favicons/onecloud/super_cloud.png"><link rel="canonical" href="https://docs.cloud.google.com/compute/docs/gpus"><link rel="search" type="application/opensearchdescription+xml"
            title="Google Cloud Documentation" href="https://docs.cloud.google.com/s/opensearch.xml">
      <link rel="alternate" hreflang="en"
          href="https://docs.cloud.google.com/compute/docs/gpus" /><link rel="alternate" hreflang="x-default" href="https://docs.cloud.google.com/compute/docs/gpus" /><link rel="alternate" hreflang="zh-Hans"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=zh-cn" /><link rel="alternate" hreflang="zh-Hant"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=zh-tw" /><link rel="alternate" hreflang="fr"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=fr" /><link rel="alternate" hreflang="de"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=de" /><link rel="alternate" hreflang="he"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=he" /><link rel="alternate" hreflang="id"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=id" /><link rel="alternate" hreflang="it"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=it" /><link rel="alternate" hreflang="ja"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=ja" /><link rel="alternate" hreflang="ko"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=ko" /><link rel="alternate" hreflang="pt-BR"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=pt-br" /><link rel="alternate" hreflang="pt"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=pt" /><link rel="alternate" hreflang="es"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=es" /><link rel="alternate" hreflang="es-419"
          href="https://docs.cloud.google.com/compute/docs/gpus?hl=es-419" /><link rel="alternate" hreflang="en"
          href="https://berlin.devsitetest.how/compute/docs/gpus" /><link rel="alternate" hreflang="x-default" href="https://berlin.devsitetest.how/compute/docs/gpus" /><link rel="alternate" hreflang="zh-Hans"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=zh-cn" /><link rel="alternate" hreflang="zh-Hant"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=zh-tw" /><link rel="alternate" hreflang="fr"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=fr" /><link rel="alternate" hreflang="de"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=de" /><link rel="alternate" hreflang="he"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=he" /><link rel="alternate" hreflang="id"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=id" /><link rel="alternate" hreflang="it"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=it" /><link rel="alternate" hreflang="ja"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=ja" /><link rel="alternate" hreflang="ko"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=ko" /><link rel="alternate" hreflang="pt-BR"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=pt-br" /><link rel="alternate" hreflang="pt"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=pt" /><link rel="alternate" hreflang="es"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=es" /><link rel="alternate" hreflang="es-419"
          href="https://berlin.devsitetest.how/compute/docs/gpus?hl=es-419" /><title>GPU machine types &nbsp;|&nbsp; Compute Engine &nbsp;|&nbsp; Google Cloud Documentation</title>

<meta property="og:title" content="GPU machine types &nbsp;|&nbsp; Compute Engine &nbsp;|&nbsp; Google Cloud Documentation"><meta name="description" content="Understand instance options available to support GPU-accelerated workloads such as machine learning, data processing, and graphics workloads on Compute Engine.">
  <meta property="og:description" content="Understand instance options available to support GPU-accelerated workloads such as machine learning, data processing, and graphics workloads on Compute Engine."><meta property="og:url" content="https://docs.cloud.google.com/compute/docs/gpus"><meta property="og:image" content="https://docs.cloud.google.com/_static/cloud/images/social-icon-google-cloud-1200-630.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630"><meta property="og:locale" content="en"><meta name="twitter:card" content="summary_large_image"><script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Article",
    
    "headline": "GPU machine types"
  }
</script><script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    "itemListElement": [{
      "@type": "ListItem",
      "position": 1,
      "name": "Compute Engine",
      "item": "https://docs.cloud.google.com/compute/docs"
    },{
      "@type": "ListItem",
      "position": 2,
      "name": "GPU machine types",
      "item": "https://docs.cloud.google.com/compute/docs/gpus"
    }]
  }
  </script>
  
    

    

    
  
  </p>



    
    

    

    
    

    

  <meta name="keywords" content="compute engine, gce, gcp, google cloud, nvidia gpu models, nvidia gpus, gpu machine types, gpu types, gcp gpu, a4x max a4X, a4, a3, a2, g2, a3 ultra, a3 mega, a3 high, a3 edge, a2 ultra, a2 standard, g4, n1, nvidia gb200, rtx pro 6000, b200, h200, h100, a100, l4, t4, p100, v100, machine series, gpu accelerated vms, gpu memory, gpu count"><link href="https://fonts.googleapis.com/css2?family=Google+Symbols" rel="stylesheet" data-page-link>

    </head>
  <body class="color-scheme--light"
        template="page"
        theme="clouddocs-theme"
        type="article"
        
        appearance
        
        layout="docs"
        
        
        free-trial
        
        
        display-toc
        pending>
  
    <devsite-progress type="indeterminate" id="app-progress"></devsite-progress>
  
  
    <a href="#main-content" class="skip-link button">
      
      Skip to main content
    </a>
    <section class="devsite-wrapper">
      <devsite-cookie-notification-bar></devsite-cookie-notification-bar>
        <cloudx-track userCountry="US"></cloudx-track>

<devsite-header role="banner" keep-tabs-visible>
  
    





















<div class="devsite-header--inner" data-nosnippet>
  <div class="devsite-top-logo-row-wrapper-wrapper">
    <div class="devsite-top-logo-row-wrapper">
      <div class="devsite-top-logo-row">
        <button type="button" id="devsite-hamburger-menu"
          class="devsite-header-icon-button button-flat material-icons gc-analytics-event"
          data-category="Site-Wide Custom Events"
          data-label="Navigation menu button"
          visually-hidden
          aria-label="Open menu">
        </button>
        
<div class="devsite-product-name-wrapper">

  <a href="/" class="devsite-site-logo-link gc-analytics-event"
   data-category="Site-Wide Custom Events" data-label="Site logo" track-type="globalNav"
   track-name="googleCloudDocumentation" track-metadata-position="nav"
   track-metadata-eventDetail="nav">
  
  <picture>
    
    <source srcset="https://www.gstatic.com/devrel-devsite/prod/vb08cbdb02acf7f66ad9727ddfba9d81df8806422eb5dd63dba194c9c8c7997f7/clouddocs/images/lockup-dark-theme.svg"
            media="(prefers-color-scheme: dark)"
            class="devsite-dark-theme">
    
    <img src="https://www.gstatic.com/devrel-devsite/prod/vb08cbdb02acf7f66ad9727ddfba9d81df8806422eb5dd63dba194c9c8c7997f7/clouddocs/images/lockup.svg" class="devsite-site-logo" alt="Google Cloud Documentation">
  </picture>
  
</a>



</div>
        <div class="devsite-top-logo-row-middle">
          <div class="devsite-header-upper-tabs">
            
              
              
  <devsite-tabs class="upper-tabs">

    <nav class="devsite-tabs-wrapper" aria-label="Upper tabs">
      
        
          <tab class="devsite-dropdown
    
    devsite-active
    devsite-clickable
    ">
  
    <a href="https://docs.cloud.google.com/docs"
    class="devsite-tabs-content gc-analytics-event "
      track-metadata-eventdetail="https://docs.cloud.google.com/docs"
    
       track-type="nav"
       track-metadata-position="nav - docs-home"
       track-metadata-module="primary nav"
       aria-label="Technology areas, selected" 
       
         
           data-category="Site-Wide Custom Events"
         
           data-label="Tab: Technology areas"
         
           track-name="docs-home"
         
           track-link-column-type="single-column"
         
       >
    Technology areas
  
    </a>
    
      <button
         aria-haspopup="menu"
         aria-expanded="false"
         aria-label="Dropdown menu for Technology areas"
         track-type="nav"
         track-metadata-eventdetail="https://docs.cloud.google.com/docs"
         track-metadata-position="nav - docs-home"
         track-metadata-module="primary nav"
         
          
            data-category="Site-Wide Custom Events"
          
            data-label="Tab: Technology areas"
          
            track-name="docs-home"
          
            track-link-column-type="single-column"
          
        
         class="devsite-tabs-dropdown-toggle devsite-icon devsite-icon-arrow-drop-down"></button>
    
  
  <div class="devsite-tabs-dropdown" role="menu" aria-label="submenu" hidden>
    <div class="devsite-tabs-dropdown-content">
      
        <button class="devsite-tabs-close-button material-icons button-flat gc-analytics-event"
                data-category="Site-Wide Custom Events"
                data-label="Close dropdown menu"
                aria-label="Close dropdown menu"
                track-type="nav"
                track-name="close"
                track-metadata-eventdetail="#"
                track-metadata-position="nav - docs-home"
                track-metadata-module="tertiary nav">close</button>
      
      
        <div class="devsite-tabs-dropdown-column
                    ">
          
            <ul class="devsite-tabs-dropdown-section
                       ">
              
              
              
                <li class="devsite-nav-item">
                  <a href="https://docs.cloud.google.com/docs/ai-ml"
                    
                     track-type="nav"
                     track-metadata-eventdetail="https://docs.cloud.google.com/docs/ai-ml"
                     track-metadata-position="nav - docs-home"
                     track-metadata-module="tertiary nav"
                     
                     tooltip
                  >
                    
                    <div class="devsite-nav-item-title">
                      AI and ML
                    </div>
                    
                  </a>
                </li>
              
                <li class="devsite-nav-item">
                  <a href="https://docs.cloud.google.com/docs/application-development"
                    
                     track-type="nav"
                     track-metadata-eventdetail="https://docs.cloud.google.com/docs/application-development"
                     track-metadata-position="nav - docs-home"
                     track-metadata-module="tertiary nav"
                     
                     tooltip
                  >
                    
                    <div class="devsite-nav-item-title">
                      Application development
                    </div>
                    
                  </a>
                </li>
              
                <li class="devsite-nav-item">
                  <a href="https://docs.cloud.google.com/docs/application-hosting"
                    
                     track-type="nav"
                     track-metadata-eventdetail="https://docs.cloud.google.com/docs/application-hosting"
                     track-metadata-position="nav - docs-home"
                     track-metadata-module="tertiary nav"
                     
                     tooltip
                  >
                    
                    <div class="devsite-nav-item-title">
                      Application hosting
                    </div>
                    
                  </a>
                </li>
              
                <li class="devsite-nav-item">
                  <a href="https://docs.cloud.google.com/docs/compute-area"
                    
                     track-type="nav"
                     track-metadata-eventdetail="https://docs.cloud.google.com/docs/compute-area"
                     track-metadata-position="nav - docs-home"
                     track-metadata-module="tertiary nav"
                