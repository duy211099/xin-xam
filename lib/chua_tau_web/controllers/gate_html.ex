defmodule ChuaTauWeb.GateHTML do
  use ChuaTauWeb, :html

  alias ChuaTauWeb.Machines

  embed_templates "gate_html/*"

  @vignettes %{
    "gate" => "0 400 1200 400",
    "court" => "200 200 800 533",
    "hall" => "200 0 800 533"
  }

  @doc "The whole courtyard scene. Decorative: the machines are links laid over it."
  def scene(assigns) do
    ~H"""
    <svg class="scene" viewBox="0 0 1200 800" aria-hidden="true" focusable="false">
      <g id="scene-art"><.scene_art /></g>
    </svg>
    """
  end

  attr :part, :string, required: true, values: Map.keys(@vignettes)

  @doc "A crop of the scene art, for the phone walk."
  def vignette(assigns) do
    assigns = assign(assigns, :view_box, Map.fetch!(@vignettes, assigns.part))

    ~H"""
    <svg
      class={"vignette vignette-#{@part}"}
      viewBox={@view_box}
      aria-hidden="true"
      focusable="false"
    >
      <use href="#scene-art" />
    </svg>
    """
  end
end
