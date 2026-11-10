---
layout: page
title: projects
permalink: /projects/
description: Open-source projects, cloud infrastructure, and IoT telemetry systems.
nav: true
nav_order: 1
horizontal: false
---

<!-- pages/projects.md -->
<div class="projects">
  {% assign sorted_projects = site.projects | sort: "importance" %}
  <div class="row row-cols-1 row-cols-md-2">
    {% for project in sorted_projects %}
      {% include projects.liquid %}
    {% endfor %}
  </div>
</div>
