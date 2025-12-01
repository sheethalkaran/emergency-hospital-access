import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../models/hospital.dart';
import '../widgets/hospital_card.dart';
import 'hospital_detail_screen.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([_loadHospitals(), _getCurrentLocation()]);
  }

  Future<void> _loadHospitals() async {
    final provider = Provider.of<HospitalProvider>(context, listen: false);
    provider.setLoading(true);

    try {
      final hospitals = await ApiService.getAllHospitals();
      provider.setHospitals(hospitals);
    } catch (e) {
      _showErrorSnackBar('Failed to load hospitals: ${e.toString()}');
    }

    provider.setLoading(false);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(
          'Location permissions are permanently denied, please enable in settings.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to get location: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(20),
          elevation: 8,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF6B73FF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildEnhancedHeader(),
              _buildModernSearchBar(),
              _buildAdvancedTabBar(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, -10),
                      ),
                    ],
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNearbyHospitalsTab(),
                      _buildAllHospitalsTab(),
                      _buildSearchTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      ChatbotScreen(userLocation: _currentPosition),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOutCubic;

                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));

                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          );
        },
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 8,
        tooltip: 'Chat with Assistant',
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'HospitalFinder',
          style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A000000),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            Provider.of<HospitalProvider>(
              context,
              listen: false,
            ).setSearchQuery(value);
          },
          decoration: InputDecoration(
            hintText: 'Search hospitals...',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(10),
              child: ShaderMask(
                shaderCallback:
                    (bounds) => const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                    ).createShader(bounds),
                child: const Icon(
                  Icons.search_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        Provider.of<HospitalProvider>(
                          context,
                          listen: false,
                        ).setSearchQuery('');
                      },
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF667EEA),
        unselectedLabelColor: Colors.white,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.near_me_rounded, size: 18),
                SizedBox(width: 6),
                Text('Nearby'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list_alt_rounded, size: 18),
                SizedBox(width: 6),
                Text('All'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, size: 18),
                SizedBox(width: 6),
                Text('Search'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyHospitalsTab() {
    if (_currentPosition == null) {
      return _buildLocationPrompt();
    }

    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return _buildLoadingState();
        }

        // Get nearby hospitals and apply search filter
        final nearbyHospitals = provider.getNearbyHospitals(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );

        // Apply search query filter
        final query = provider.searchQuery.toLowerCase();
        final filteredNearby =
            query.isEmpty
                ? nearbyHospitals
                : nearbyHospitals.where((hospital) {
                  final nameMatch = hospital.name.toLowerCase().contains(query);
                  final addressMatch = hospital.address.toLowerCase().contains(
                    query,
                  );
                  return nameMatch || addressMatch;
                }).toList();

        if (filteredNearby.isEmpty) {
          return _buildEmptyState(
            query.isEmpty
                ? 'No nearby hospitals found within 50km'
                : 'No nearby hospitals match your search',
          );
        }

        return RefreshIndicator(
          onRefresh: _loadHospitals,
          color: const Color(0xFF667EEA),
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: filteredNearby.length,
            itemBuilder: (context, index) {
              final hospital = filteredNearby[index];
              return HospitalCard(
                hospital: hospital,
                currentPosition: _currentPosition,
                onTap: () => _navigateToDetail(hospital),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAllHospitalsTab() {
    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        if (provider.loading) {
          return _buildLoadingState();
        }

        if (provider.hospitals.isEmpty) {
          return _buildEmptyState('No hospitals found');
        }

        // Sort hospitals by distance if location is available
        final hospitalsToShow =
            _currentPosition != null
                ? (List<Hospital>.from(provider.filteredHospitals)
                  ..sort((a, b) {
                    final distA = a.distanceFrom(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    );
                    final distB = b.distanceFrom(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    );
                    return distA.compareTo(distB);
                  }))
                : provider.filteredHospitals;

        return RefreshIndicator(
          onRefresh: _loadHospitals,
          color: const Color(0xFF667EEA),
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: hospitalsToShow.length,
            itemBuilder: (context, index) {
              final hospital = hospitalsToShow[index];
              return HospitalCard(
                hospital: hospital,
                currentPosition: _currentPosition,
                onTap: () => _navigateToDetail(hospital),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        // Memoize sorted results to avoid recalculating on every rebuild
        final resultsToShow = provider.filteredHospitals;
        final hasActiveFilters =
            provider.searchQuery.isNotEmpty ||
            provider.selectedState.isNotEmpty ||
            provider.selectedDistrict.isNotEmpty;

        if (resultsToShow.isEmpty && !hasActiveFilters) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFilterSection(provider),
                const SizedBox(height: 24),
                _buildSearchPrompt(),
              ],
            ),
          );
        }

        if (resultsToShow.isEmpty && hasActiveFilters) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFilterSection(provider),
                const SizedBox(height: 24),
                _buildEmptyState('No hospitals match your search criteria'),
              ],
            ),
          );
        }

        // Use CustomScrollView with Slivers for better performance
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildFilterSection(provider),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Text(
                  'Search Results (${resultsToShow.length})',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final hospital = resultsToShow[index];
                  return HospitalCard(
                    hospital: hospital,
                    currentPosition: _currentPosition,
                    onTap: () => _navigateToDetail(hospital),
                  );
                }, childCount: resultsToShow.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection(HospitalProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Advanced Filters',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // State Dropdown
            DropdownButtonFormField<String>(
              value:
                  provider.selectedState.isEmpty
                      ? null
                      : provider.selectedState,
              decoration: InputDecoration(
                labelText: 'Select State',
                labelStyle: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF667EEA),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              items:
                  ['', ...provider.states].map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(
                        state.isEmpty ? 'All States' : state,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                provider.setSelectedState(value ?? '');
              },
            ),

            const SizedBox(height: 20),

            // District Dropdown
            DropdownButtonFormField<String>(
              value:
                  provider.selectedDistrict.isEmpty
                      ? null
                      : provider.selectedDistrict,
              decoration: InputDecoration(
                labelText: 'Select District',
                labelStyle: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF667EEA),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              items:
                  ['', ...provider.getDistricts(provider.selectedState)].map((
                    district,
                  ) {
                    return DropdownMenuItem(
                      value: district,
                      child: Text(
                        district.isEmpty ? 'All Districts' : district,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                provider.setSelectedDistrict(value ?? '');
              },
            ),

            const SizedBox(height: 20),

            // Clear Filters Button
            if (provider.selectedState.isNotEmpty ||
                provider.selectedDistrict.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    provider.clearFilters();
                  },
                  icon: const Icon(
                    Icons.clear_all_rounded,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Clear All Filters',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading Hospitals...',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we fetch the latest data',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search criteria or check your location settings',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPrompt() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Location Access Required',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enable location services to discover hospitals near you and get accurate distance measurements',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  'Enable Location',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Advanced Search & Filters',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Use the search bar above or apply filters to find hospitals that match your specific requirements',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_city_rounded,
                          color: const Color(0xFF667EEA),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By Location',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.medical_services_rounded,
                          color: const Color(0xFF667EEA),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By Specialty',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: const Color(0xFF667EEA),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'By Type',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Hospital hospital) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => HospitalDetailScreen(
              hospital: hospital,
              currentPosition: _currentPosition,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
