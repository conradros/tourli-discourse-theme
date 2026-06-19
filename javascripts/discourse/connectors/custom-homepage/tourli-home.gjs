import TourliHome from "../../components/tourli-home";

// Mounts the Tourli homepage into the custom-homepage outlet. Active because
// about.json sets the custom_homepage theme modifier, which routes "/" here.
<template><TourliHome @model={{@outletArgs.model}} /></template>
