package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.*;
import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import io.jmix.core.security.Authenticated;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AuthService {

    private final DataManager dataManager;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;
    private final AuthenticationManager authenticationManager;

    public AuthService(
            DataManager dataManager,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            UserDetailsService userDetailsService,
            AuthenticationManager authenticationManager
    ) {
        this.dataManager = dataManager;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.userDetailsService = userDetailsService;
        this.authenticationManager = authenticationManager;
    }

    @Authenticated
    @Transactional
    public void register(RegisterRequest request) {
        if (usernameExists(request.getUsername())) {
            throw new IllegalArgumentException("Username already exists");
        }

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            throw new IllegalArgumentException("Passwords do not match");
        }

        User user = dataManager.create(User.class);
        user.setUsername(request.getUsername());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setActive(true);

        dataManager.save(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getUsername(),
                        request.getPassword()
                )
        );

        UserDetails user = userDetailsService.loadUserByUsername(request.getUsername());

        if (!user.isEnabled()) {
            throw new IllegalArgumentException("Account is not activated");
        }

        String accessToken = jwtService.generateToken(user);
        String refreshToken = jwtService.generateRefreshToken(user);

        return new AuthResponse(accessToken, refreshToken);
    }

    @Authenticated
    private boolean usernameExists(String username) {
        List<User> users = dataManager.load(User.class)
                .query("select e from User e where e.username = :username")
                .parameter("username", username)
                .list();
        return !users.isEmpty();
    }
}
