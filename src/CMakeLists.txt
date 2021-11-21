add_library(asteroid-2048 main.cpp resources.qrc)
set_target_properties(asteroid-2048 PROPERTIES PREFIX "" SUFFIX "")

target_link_libraries(asteroid-2048 PUBLIC
	AsteroidApp)

install(TARGETS asteroid-2048
	DESTINATION ${CMAKE_INSTALL_BINDIR})