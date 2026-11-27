add_library(asteroid-music main.cpp)
set_target_properties(asteroid-music PROPERTIES PREFIX "")

asteroid_app_qml_module(asteroid-music
	main.qml
	media.js
	MarqueeText.qml
	SwapText.qml
	PlayPauseButton.qml
	SkipButton.qml
	OutputRow.qml
	LevelArc.qml
	CrownVolume.qml
	VolumePage.qml
	PlayerPage.qml
	ArtBackground.qml
	MediaLink.qml
)

target_link_libraries(
	asteroid-music
	PUBLIC
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-music
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
